import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '../lib/api';

interface Seat {
  id?: string;
  row: string;
  number: number;
  category: 'FRONT' | 'STANDARD' | 'PREMIUM' | 'RECLINER';
}

interface Screen {
  id: string;
  name: string;
  type: string;
  format: string;
  equipment: string[];
  managerId: string | null;
  seats?: Seat[];
}

interface Theatre {
  id: string;
  name: string;
  screens: Screen[];
}

export default function ScreensPage() {
  const queryClient = useQueryClient();
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingScreen, setEditingScreen] = useState<Screen | null>(null);
  const [selectedTheatreId, setSelectedTheatreId] = useState<string>('');

  const { data: theatres, isLoading } = useQuery({
    queryKey: ['theatres', 'with-screens'],
    queryFn: async () => {
      const res = await api.get<{ theatres: Theatre[] }>('/theatres');
      return res.data.theatres;
    },
  });

  const saveScreen = useMutation({
    mutationFn: async (data: any) => {
      if (editingScreen) {
        await api.patch(`/admin/screens/${editingScreen.id}`, data);
      } else {
        await api.post('/admin/screens', data);
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['theatres', 'with-screens'] });
      setIsFormOpen(false);
      setEditingScreen(null);
    },
  });

  if (isLoading) return <div className="loading">Loading screens...</div>;

  return (
    <div className="page-container">
      <div className="flex-row" style={{ justifyContent: 'space-between', marginBottom: '1.5rem' }}>
        <h2 style={{ margin: 0 }}>Screens Config</h2>
        <button onClick={() => { setEditingScreen(null); setIsFormOpen(true); }}>+ Add Screen</button>
      </div>

      {isFormOpen && (
        <ScreenForm 
          screen={editingScreen}
          theatres={theatres || []}
          initialTheatreId={selectedTheatreId}
          onSave={(data) => saveScreen.mutate(data)}
          onCancel={() => { setIsFormOpen(false); setEditingScreen(null); }}
          isSaving={saveScreen.isPending}
        />
      )}

      {theatres?.map((t) => (
        <div key={t.id} style={{ marginBottom: '2rem' }}>
          <h3>{t.name}</h3>
          {t.screens.length === 0 ? (
            <p className="text-muted">No screens in this theatre.</p>
          ) : (
            <div className="table-wrapper" style={{ marginTop: '1rem' }}>
              <table>
                <thead>
                  <tr>
                    <th>Name</th>
                    <th>Type / Format</th>
                    <th>Equipment</th>
                    <th>Manager ID</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {t.screens.map(s => (
                    <tr key={s.id}>
                      <td><div style={{ fontWeight: 600 }}>{s.name}</div></td>
                      <td>
                        <div className="badge secondary">{s.type}</div>
                        <div className="badge secondary" style={{ marginLeft: '0.5rem' }}>{s.format}</div>
                      </td>
                      <td>{s.equipment.join(', ') || '-'}</td>
                      <td><span className="text-sm text-muted">{s.managerId || 'Unassigned'}</span></td>
                      <td>
                        <button 
                          className="btn-small secondary"
                          onClick={() => {
                            setSelectedTheatreId(t.id);
                            setEditingScreen(s);
                            setIsFormOpen(true);
                          }}
                        >
                          Edit
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      ))}
    </div>
  );
}

function ScreenForm({ screen, theatres, initialTheatreId, onSave, onCancel, isSaving }: {
  screen: Screen | null;
  theatres: Theatre[];
  initialTheatreId: string;
  onSave: (data: any) => void;
  onCancel: () => void;
  isSaving: boolean;
}) {
  const [formData, setFormData] = useState({
    theatreId: initialTheatreId || (theatres.length > 0 ? theatres[0].id : ''),
    name: screen?.name || '',
    type: screen?.type || 'STANDARD',
    format: screen?.format || '2D',
    equipment: screen?.equipment.join(', ') || '',
    managerId: screen?.managerId || '',
  });

  const { data: screenDetails, isLoading: loadingDetails } = useQuery({
    queryKey: ['screen', screen?.id],
    queryFn: async () => {
      const res = await api.get<{ screen: Screen }>(`/screens/${screen?.id}`);
      return res.data.screen;
    },
    enabled: !!screen?.id,
  });

  // Seat layout state
  const [layout, setLayout] = useState<Seat[]>([]);
  const [layoutInitialized, setLayoutInitialized] = useState(false);

  // Initialize layout from fetched details
  if (screenDetails && !layoutInitialized && screenDetails.seats) {
    setLayout(screenDetails.seats.map(s => ({ row: s.row, number: s.number, category: s.category as any })));
    setLayoutInitialized(true);
  } else if (!screen && !layoutInitialized) {
    setLayoutInitialized(true); // new screen, empty layout
  }

  const generateLayout = () => {
    const rows = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'];
    const seatsPerRow = 15;
    const newLayout: Seat[] = [];
    rows.forEach(row => {
      for (let i = 1; i <= seatsPerRow; i++) {
        const cat = row === 'A' ? 'FRONT' : row === 'J' ? 'RECLINER' : (row === 'H' || row === 'I') ? 'PREMIUM' : 'STANDARD';
        newLayout.push({ row, number: i, category: cat });
      }
    });
    setLayout(newLayout);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const data: any = {
      ...formData,
      equipment: formData.equipment.split(',').map(s => s.trim()).filter(Boolean),
      managerId: formData.managerId || null,
      seats: layout,
    };
    if (screen) delete data.theatreId; // don't patch theatreId
    onSave(data);
  };

  if (screen && loadingDetails) return <div style={{ padding: '2rem' }}>Loading details...</div>;

  // Group seats by row for editor
  const rows = Array.from(new Set(layout.map(s => s.row))).sort();
  
  return (
    <div style={{ background: 'var(--surface)', padding: '1.5rem', borderRadius: 8, marginBottom: '2rem', border: '1px solid var(--border)' }}>
      <h3>{screen ? 'Edit Screen' : 'Add New Screen'}</h3>
      <form onSubmit={handleSubmit} style={{ marginTop: '1rem' }}>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginBottom: '1.5rem' }}>
          {!screen && (
            <div>
              <label>Theatre</label>
              <select required value={formData.theatreId} onChange={e => setFormData({ ...formData, theatreId: e.target.value })}>
                {theatres.map(t => <option key={t.id} value={t.id}>{t.name}</option>)}
              </select>
            </div>
          )}
          <div>
            <label>Screen Name (e.g. Screen 1)</label>
            <input required value={formData.name} onChange={e => setFormData({ ...formData, name: e.target.value })} />
          </div>
          <div>
            <label>Type</label>
            <select required value={formData.type} onChange={e => setFormData({ ...formData, type: e.target.value })}>
              <option value="STANDARD">STANDARD</option>
              <option value="IMAX">IMAX</option>
              <option value="FOURDX">4DX</option>
              <option value="DOLBY_ATMOS">DOLBY ATMOS</option>
            </select>
          </div>
          <div>
            <label>Format</label>
            <input required value={formData.format} onChange={e => setFormData({ ...formData, format: e.target.value })} placeholder="2D, 3D" />
          </div>
          <div>
            <label>Equipment (comma separated)</label>
            <input value={formData.equipment} onChange={e => setFormData({ ...formData, equipment: e.target.value })} />
          </div>
          <div>
            <label>Manager ID (optional)</label>
            <input value={formData.managerId} onChange={e => setFormData({ ...formData, managerId: e.target.value })} />
          </div>
        </div>

        <hr style={{ borderColor: 'var(--border)', margin: '1.5rem 0' }} />
        
        <div className="flex-row" style={{ justifyContent: 'space-between', marginBottom: '1rem' }}>
          <h4>Seat Layout</h4>
          {layout.length === 0 && <button type="button" className="btn-small secondary" onClick={generateLayout}>Generate Standard 10x15</button>}
          {layout.length > 0 && <button type="button" className="btn-small secondary text-danger" onClick={() => setLayout([])}>Clear Layout</button>}
        </div>

        {layout.length > 0 && (
          <div style={{ overflowX: 'auto', paddingBottom: '1rem' }}>
            <div style={{ background: '#000', padding: '0.25rem', textAlign: 'center', color: '#fff', fontSize: '0.75rem', marginBottom: '2rem', borderRadius: 4, letterSpacing: '0.5em' }}>SCREEN</div>
            {rows.map(row => {
              const rowSeats = layout.filter(s => s.row === row).sort((a, b) => a.number - b.number);
              return (
                <div key={row} className="flex-row" style={{ justifyContent: 'center', marginBottom: '0.5rem' }}>
                  <div style={{ width: 24, textAlign: 'center', fontWeight: 'bold' }}>{row}</div>
                  {rowSeats.map(seat => (
                    <div 
                      key={`${seat.row}${seat.number}`}
                      title={`${seat.row}${seat.number} - ${seat.category}`}
                      style={{
                        width: 24,
                        height: 24,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        fontSize: '0.6rem',
                        borderRadius: '4px 4px 0 0',
                        cursor: 'pointer',
                        background: seat.category === 'FRONT' ? '#94a3b8' 
                                  : seat.category === 'STANDARD' ? '#64748b'
                                  : seat.category === 'PREMIUM' ? '#f59e0b'
                                  : '#ec4899', // RECLINER
                        color: '#fff'
                      }}
                      onClick={() => {
                        // Cycle category on click
                        const cats: any[] = ['FRONT', 'STANDARD', 'PREMIUM', 'RECLINER'];
                        const nextCat = cats[(cats.indexOf(seat.category) + 1) % cats.length];
                        setLayout(layout.map(s => s.row === seat.row && s.number === seat.number ? { ...s, category: nextCat } : s));
                      }}
                    >
                      {seat.number}
                    </div>
                  ))}
                  <div style={{ width: 24 }} />
                </div>
              );
            })}
            <div className="flex-row text-xs text-muted" style={{ justifyContent: 'center', marginTop: '1.5rem', gap: '1rem' }}>
              <div className="flex-row"><div style={{ width: 12, height: 12, background: '#94a3b8' }}/> Front</div>
              <div className="flex-row"><div style={{ width: 12, height: 12, background: '#64748b' }}/> Standard</div>
              <div className="flex-row"><div style={{ width: 12, height: 12, background: '#f59e0b' }}/> Premium</div>
              <div className="flex-row"><div style={{ width: 12, height: 12, background: '#ec4899' }}/> Recliner</div>
              <div style={{ marginLeft: '1rem' }}>(Click seats to change category)</div>
            </div>
          </div>
        )}

        <div className="flex-row" style={{ marginTop: '2rem' }}>
          <button type="submit" disabled={isSaving}>{isSaving ? 'Saving...' : 'Save Screen'}</button>
          <button type="button" className="secondary" onClick={onCancel} disabled={isSaving}>Cancel</button>
        </div>
      </form>
    </div>
  );
}
