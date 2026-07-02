import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '../lib/api';

interface Theatre {
  id: string;
  chain: string;
  name: string;
  city: string;
  address: string;
}

export default function TheatresPage() {
  const queryClient = useQueryClient();
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingTheatre, setEditingTheatre] = useState<Theatre | null>(null);

  const { data: theatres, isLoading } = useQuery({
    queryKey: ['theatres'],
    queryFn: async () => {
      const res = await api.get<{ theatres: Theatre[] }>('/theatres');
      return res.data.theatres;
    },
  });

  const saveTheatre = useMutation({
    mutationFn: async (data: any) => {
      if (editingTheatre) {
        await api.patch(`/admin/theatres/${editingTheatre.id}`, data);
      } else {
        await api.post('/admin/theatres', data);
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['theatres'] });
      setIsFormOpen(false);
      setEditingTheatre(null);
    },
  });

  if (isLoading) return <div className="loading">Loading theatres...</div>;

  return (
    <div className="page-container">
      <div className="flex-row" style={{ justifyContent: 'space-between', marginBottom: '1.5rem' }}>
        <h2 style={{ margin: 0 }}>Theatres</h2>
        <button onClick={() => { setEditingTheatre(null); setIsFormOpen(true); }}>+ Add Theatre</button>
      </div>

      {isFormOpen && (
        <TheatreForm 
          theatre={editingTheatre} 
          onSave={(data) => saveTheatre.mutate(data)}
          onCancel={() => { setIsFormOpen(false); setEditingTheatre(null); }}
          isSaving={saveTheatre.isPending}
        />
      )}

      <div className="table-wrapper">
        <table>
          <thead>
            <tr>
              <th>Chain / Name</th>
              <th>City</th>
              <th>Address</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {theatres?.map((t) => (
              <tr key={t.id}>
                <td>
                  <div style={{ fontWeight: 600 }}>{t.name}</div>
                  <div className="text-xs text-muted">{t.chain}</div>
                </td>
                <td>{t.city}</td>
                <td><div className="text-sm" style={{ maxWidth: 300, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{t.address}</div></td>
                <td>
                  <button 
                    className="btn-small secondary"
                    onClick={() => { setEditingTheatre(t); setIsFormOpen(true); }}
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

function TheatreForm({ theatre, onSave, onCancel, isSaving }: { 
  theatre: Theatre | null; 
  onSave: (data: any) => void; 
  onCancel: () => void;
  isSaving: boolean;
}) {
  const [formData, setFormData] = useState({
    chain: theatre?.chain || '',
    name: theatre?.name || '',
    city: theatre?.city || '',
    address: theatre?.address || '',
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSave(formData);
  };

  return (
    <div style={{ background: 'var(--surface)', padding: '1.5rem', borderRadius: 8, marginBottom: '2rem', border: '1px solid var(--border)' }}>
      <h3>{theatre ? 'Edit Theatre' : 'Add New Theatre'}</h3>
      <form onSubmit={handleSubmit} style={{ marginTop: '1rem', display: 'grid', gap: '1rem', gridTemplateColumns: '1fr 1fr' }}>
        <div>
          <label>Chain Name</label>
          <input required value={formData.chain} onChange={e => setFormData({ ...formData, chain: e.target.value })} />
        </div>
        <div>
          <label>Theatre Name</label>
          <input required value={formData.name} onChange={e => setFormData({ ...formData, name: e.target.value })} />
        </div>
        <div>
          <label>City</label>
          <input required value={formData.city} onChange={e => setFormData({ ...formData, city: e.target.value })} />
        </div>
        <div style={{ gridColumn: '1 / -1' }}>
          <label>Address</label>
          <textarea required rows={2} value={formData.address} onChange={e => setFormData({ ...formData, address: e.target.value })} />
        </div>
        <div className="flex-row" style={{ gridColumn: '1 / -1', marginTop: '0.5rem' }}>
          <button type="submit" disabled={isSaving}>{isSaving ? 'Saving...' : 'Save Theatre'}</button>
          <button type="button" className="secondary" onClick={onCancel} disabled={isSaving}>Cancel</button>
        </div>
      </form>
    </div>
  );
}
