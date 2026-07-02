import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '../lib/api';

interface Movie {
  id: string;
  title: string;
  description: string;
  runtimeMin: number;
  cast: string[];
  posterUrl: string | null;
  trailerUrl: string | null;
  releaseDate: string;
  ageRating: string;
  languages: string[];
  genres?: { id: string; name: string }[];
}

interface Genre {
  id: string;
  name: string;
}

export default function MoviesPage() {
  const queryClient = useQueryClient();
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingMovie, setEditingMovie] = useState<Movie | null>(null);

  const { data: movies, isLoading: loadingMovies } = useQuery({
    queryKey: ['movies'],
    queryFn: async () => {
      const res = await api.get<{ movies: Movie[] }>('/movies');
      return res.data.movies;
    },
  });

  const { data: genres } = useQuery({
    queryKey: ['genres'],
    queryFn: async () => {
      const res = await api.get<{ genres: Genre[] }>('/genres');
      return res.data.genres;
    },
  });

  const saveMovie = useMutation({
    mutationFn: async (data: any) => {
      if (editingMovie) {
        await api.patch(`/admin/movies/${editingMovie.id}`, data);
      } else {
        await api.post('/admin/movies', data);
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['movies'] });
      setIsFormOpen(false);
      setEditingMovie(null);
    },
  });

  if (loadingMovies) return <div className="loading">Loading movies...</div>;

  return (
    <div className="page-container">
      <div className="flex-row" style={{ justifyContent: 'space-between', marginBottom: '1.5rem' }}>
        <h2 style={{ margin: 0 }}>Movies Catalog</h2>
        <button onClick={() => { setEditingMovie(null); setIsFormOpen(true); }}>+ Add Movie</button>
      </div>

      {isFormOpen && (
        <MovieForm 
          movie={editingMovie} 
          genres={genres || []} 
          onSave={(data) => saveMovie.mutate(data)}
          onCancel={() => { setIsFormOpen(false); setEditingMovie(null); }}
          isSaving={saveMovie.isPending}
        />
      )}

      <div className="table-wrapper">
        <table>
          <thead>
            <tr>
              <th>Movie</th>
              <th>Details</th>
              <th>Release</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {movies?.map((m) => (
              <tr key={m.id}>
                <td>
                  <div className="flex-row" style={{ alignItems: 'flex-start' }}>
                    {m.posterUrl ? (
                      <img src={m.posterUrl} alt={m.title} style={{ width: 48, height: 72, objectFit: 'cover', borderRadius: 4 }} />
                    ) : (
                      <div style={{ width: 48, height: 72, background: 'var(--border)', borderRadius: 4 }} />
                    )}
                    <div>
                      <div style={{ fontWeight: 600 }}>{m.title}</div>
                      <div className="text-xs text-muted">{m.ageRating} • {m.runtimeMin}m</div>
                      <div className="text-xs text-muted mt-1">{m.genres?.map(g => g.name).join(', ')}</div>
                    </div>
                  </div>
                </td>
                <td>
                  <div className="text-sm"><b>Langs:</b> {m.languages.join(', ')}</div>
                  <div className="text-sm" style={{ maxWidth: 200, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                    <b>Cast:</b> {m.cast.join(', ')}
                  </div>
                </td>
                <td>
                  {new Date(m.releaseDate).toLocaleDateString()}
                </td>
                <td>
                  <button 
                    className="btn-small secondary"
                    onClick={() => { setEditingMovie(m); setIsFormOpen(true); }}
                  >
                    Edit
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function MovieForm({ movie, genres, onSave, onCancel, isSaving }: { 
  movie: Movie | null; 
  genres: Genre[]; 
  onSave: (data: any) => void; 
  onCancel: () => void;
  isSaving: boolean;
}) {
  const [formData, setFormData] = useState({
    title: movie?.title || '',
    description: movie?.description || '',
    runtimeMin: movie?.runtimeMin || 120,
    cast: movie?.cast.join(', ') || '',
    posterUrl: movie?.posterUrl || '',
    trailerUrl: movie?.trailerUrl || '',
    releaseDate: movie ? new Date(movie.releaseDate).toISOString().slice(0, 16) : new Date().toISOString().slice(0, 16),
    ageRating: movie?.ageRating || 'U',
    languages: movie?.languages.join(', ') || 'English, Hindi',
    genreIds: movie?.genres?.map(g => g.id) || [],
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSave({
      ...formData,
      runtimeMin: Number(formData.runtimeMin),
      cast: formData.cast.split(',').map(s => s.trim()).filter(Boolean),
      languages: formData.languages.split(',').map(s => s.trim()).filter(Boolean),
      releaseDate: new Date(formData.releaseDate).toISOString(),
    });
  };

  const toggleGenre = (id: string) => {
    setFormData(prev => ({
      ...prev,
      genreIds: prev.genreIds.includes(id) ? prev.genreIds.filter(g => g !== id) : [...prev.genreIds, id]
    }));
  };

  return (
    <div style={{ background: 'var(--surface)', padding: '1.5rem', borderRadius: 8, marginBottom: '2rem', border: '1px solid var(--border)' }}>
      <h3>{movie ? 'Edit Movie' : 'Add New Movie'}</h3>
      <form onSubmit={handleSubmit} style={{ marginTop: '1rem' }}>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
          <div>
            <label>Title</label>
            <input required value={formData.title} onChange={e => setFormData({ ...formData, title: e.target.value })} />
          </div>
          <div>
            <label>Release Date & Time</label>
            <input type="datetime-local" required value={formData.releaseDate} onChange={e => setFormData({ ...formData, releaseDate: e.target.value })} />
          </div>
          <div style={{ gridColumn: '1 / -1' }}>
            <label>Description</label>
            <textarea required rows={3} value={formData.description} onChange={e => setFormData({ ...formData, description: e.target.value })} />
          </div>
          <div>
            <label>Runtime (minutes)</label>
            <input type="number" required value={formData.runtimeMin} onChange={e => setFormData({ ...formData, runtimeMin: Number(e.target.value) })} />
          </div>
          <div>
            <label>Age Rating</label>
            <select value={formData.ageRating} onChange={e => setFormData({ ...formData, ageRating: e.target.value })}>
              <option value="U">U</option>
              <option value="UA">UA</option>
              <option value="A">A</option>
            </select>
          </div>
          <div>
            <label>Languages (comma separated)</label>
            <input required value={formData.languages} onChange={e => setFormData({ ...formData, languages: e.target.value })} />
          </div>
          <div>
            <label>Cast (comma separated)</label>
            <input value={formData.cast} onChange={e => setFormData({ ...formData, cast: e.target.value })} />
          </div>
          <div>
            <label>Poster URL</label>
            <input type="url" value={formData.posterUrl} onChange={e => setFormData({ ...formData, posterUrl: e.target.value })} />
          </div>
          <div>
            <label>Trailer URL</label>
            <input type="url" value={formData.trailerUrl} onChange={e => setFormData({ ...formData, trailerUrl: e.target.value })} />
          </div>
          <div style={{ gridColumn: '1 / -1' }}>
            <label>Genres</label>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.5rem', marginTop: '0.5rem' }}>
              {genres.map(g => (
                <button
                  key={g.id}
                  type="button"
                  className={`badge ${formData.genreIds.includes(g.id) ? 'badge-success' : 'secondary'}`}
                  onClick={() => toggleGenre(g.id)}
                >
                  {g.name}
                </button>
              ))}
            </div>
          </div>
        </div>
        <div className="flex-row" style={{ marginTop: '1rem' }}>
          <button type="submit" disabled={isSaving}>{isSaving ? 'Saving...' : 'Save Movie'}</button>
          <button type="button" className="secondary" onClick={onCancel} disabled={isSaving}>Cancel</button>
        </div>
      </form>
    </div>
  );
}
