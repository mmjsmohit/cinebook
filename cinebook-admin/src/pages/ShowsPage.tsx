import { useState } from 'react';
import { useQuery, useMutation } from '@tanstack/react-query';
import { api } from '../lib/api';

interface Theatre {
  id: string;
  name: string;
  screens: { id: string; name: string }[];
}

interface Movie {
  id: string;
  title: string;
  runtimeMin: number;
  languages: string[];
}

export default function ShowsPage() {
  const [formData, setFormData] = useState({
    theatreId: '',
    screenId: '',
    movieId: '',
    startTime: '',
    basePrice: 20000, // paise (200 INR)
    language: '',
    format: '2D',
  });
  const [errorMsg, setErrorMsg] = useState('');
  const [successMsg, setSuccessMsg] = useState('');

  const { data: theatres, isLoading: loadingTheatres } = useQuery({
    queryKey: ['theatres', 'with-screens'],
    queryFn: async () => {
      const res = await api.get<{ theatres: Theatre[] }>('/theatres');
      return res.data.theatres;
    },
  });

  const { data: movies, isLoading: loadingMovies } = useQuery({
    queryKey: ['movies'],
    queryFn: async () => {
      const res = await api.get<{ movies: Movie[] }>('/movies');
      return res.data.movies;
    },
  });

  const createShow = useMutation({
    mutationFn: async (data: typeof formData) => {
      const res = await api.post('/admin/shows', {
        ...data,
        startTime: new Date(data.startTime).toISOString(),
      });
      return res.data.show;
    },
    onSuccess: (show) => {
      setErrorMsg('');
      setSuccessMsg(`Success! Show created with ID: ${show.id}`);
      // Reset some fields
      setFormData(prev => ({ ...prev, startTime: '' }));
    },
    onError: (err: any) => {
      setSuccessMsg('');
      setErrorMsg(err.response?.data?.error?.message || err.message || 'Failed to schedule show');
    },
  });

  if (loadingTheatres || loadingMovies) return <div className="loading">Loading dependencies...</div>;

  const selectedTheatre = theatres?.find(t => t.id === formData.theatreId);
  const selectedMovie = movies?.find(m => m.id === formData.movieId);

  // Auto-fill language if movie selected and language not set
  if (selectedMovie && !formData.language && selectedMovie.languages.length > 0) {
    setFormData(prev => ({ ...prev, language: selectedMovie.languages[0] }));
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    createShow.mutate(formData);
  };

  return (
    <div className="page-container">
      <h2>Override Scheduling</h2>
      <p className="text-muted" style={{ marginBottom: '2rem' }}>
        As an Admin, you can schedule shows on any screen, bypassing hall manager ownership.
      </p>

      <div style={{ background: 'var(--surface)', padding: '2rem', borderRadius: 8, border: '1px solid var(--border)', maxWidth: 800 }}>
        {errorMsg && <div className="error-banner">{errorMsg}</div>}
        {successMsg && (
          <div style={{ background: 'rgba(16, 185, 129, 0.1)', color: 'var(--success)', padding: '1rem', borderRadius: 8, marginBottom: '1rem', border: '1px solid rgba(16, 185, 129, 0.2)' }}>
            {successMsg}
          </div>
        )}

        <form onSubmit={handleSubmit} style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.5rem' }}>
          <div>
            <label>Theatre</label>
            <select required value={formData.theatreId} onChange={e => setFormData({ ...formData, theatreId: e.target.value, screenId: '' })}>
              <option value="" disabled>Select a theatre</option>
              {theatres?.map(t => <option key={t.id} value={t.id}>{t.name}</option>)}
            </select>
          </div>

          <div>
            <label>Screen</label>
            <select required value={formData.screenId} onChange={e => setFormData({ ...formData, screenId: e.target.value })} disabled={!selectedTheatre}>
              <option value="" disabled>Select a screen</option>
              {selectedTheatre?.screens.map(s => <option key={s.id} value={s.id}>{s.name}</option>)}
            </select>
          </div>

          <div style={{ gridColumn: '1 / -1' }}>
            <label>Movie</label>
            <select required value={formData.movieId} onChange={e => setFormData({ ...formData, movieId: e.target.value, language: '' })}>
              <option value="" disabled>Select a movie</option>
              {movies?.map(m => <option key={m.id} value={m.id}>{m.title} ({m.runtimeMin}m)</option>)}
            </select>
          </div>

          <div>
            <label>Start Time</label>
            <input type="datetime-local" required value={formData.startTime} onChange={e => setFormData({ ...formData, startTime: e.target.value })} />
          </div>

          <div>
            <label>Base Price (INR)</label>
            <input type="number" required min={50} value={formData.basePrice / 100} onChange={e => setFormData({ ...formData, basePrice: Number(e.target.value) * 100 })} />
          </div>

          <div>
            <label>Language</label>
            <select required value={formData.language} onChange={e => setFormData({ ...formData, language: e.target.value })} disabled={!selectedMovie}>
              {selectedMovie?.languages.map(l => <option key={l} value={l}>{l}</option>)}
              {!selectedMovie && <option value="" disabled>Select a movie first</option>}
            </select>
          </div>

          <div>
            <label>Format</label>
            <select required value={formData.format} onChange={e => setFormData({ ...formData, format: e.target.value })}>
              <option value="2D">2D</option>
              <option value="3D">3D</option>
              <option value="IMAX">IMAX</option>
              <option value="4DX">4DX</option>
            </select>
          </div>

          <div style={{ gridColumn: '1 / -1', marginTop: '1rem' }}>
            <button type="submit" disabled={createShow.isPending} style={{ width: '100%' }}>
              {createShow.isPending ? 'Scheduling...' : 'Force Schedule Show'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
