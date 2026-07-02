import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '../lib/api';

interface User {
  id: string;
  phone: string;
  name?: string;
  role: string;
  disabled: boolean;
  createdAt: string;
}

export default function UsersPage() {
  const queryClient = useQueryClient();
  const [editingNameId, setEditingNameId] = useState<string | null>(null);
  const [editName, setEditName] = useState('');

  const { data, isLoading } = useQuery({
    queryKey: ['users'],
    queryFn: async () => {
      const res = await api.get<{ users: User[] }>('/admin/users');
      return res.data.users;
    },
  });

  const updateRole = useMutation({
    mutationFn: async ({ id, role }: { id: string; role: string }) => {
      await api.post(`/admin/users/${id}/role`, { role });
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['users'] }),
  });

  const disableUser = useMutation({
    mutationFn: async (id: string) => {
      await api.post(`/admin/users/${id}/disable`);
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['users'] }),
  });

  const updateName = useMutation({
    mutationFn: async ({ id, name }: { id: string; name: string }) => {
      await api.patch(`/admin/users/${id}`, { name });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] });
      setEditingNameId(null);
    },
  });

  if (isLoading) return <div className="loading">Loading users...</div>;

  return (
    <div className="page-container">
      <h2>Users Management</h2>
      <div className="table-wrapper">
        <table>
          <thead>
            <tr>
              <th>ID / Created</th>
              <th>Phone</th>
              <th>Name</th>
              <th>Role</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {data?.map((u) => (
              <tr key={u.id} className={u.disabled ? 'disabled-row' : ''}>
                <td>
                  <div className="text-sm">{u.id.slice(-8)}</div>
                  <div className="text-xs text-muted">{new Date(u.createdAt).toLocaleDateString()}</div>
                </td>
                <td>{u.phone}</td>
                <td>
                  {editingNameId === u.id ? (
                    <div className="flex-row">
                      <input 
                        type="text" 
                        value={editName} 
                        onChange={(e) => setEditName(e.target.value)} 
                        autoFocus
                        style={{ padding: '0.25rem', width: '120px' }}
                      />
                      <button 
                        className="btn-small" 
                        onClick={() => updateName.mutate({ id: u.id, name: editName })}
                      >Save</button>
                      <button 
                        className="btn-small secondary" 
                        onClick={() => setEditingNameId(null)}
                      >Cancel</button>
                    </div>
                  ) : (
                    <div className="flex-row">
                      <span>{u.name || '-'}</span>
                      <button 
                        className="btn-text text-muted" 
                        onClick={() => { setEditingNameId(u.id); setEditName(u.name || ''); }}
                      >✎</button>
                    </div>
                  )}
                </td>
                <td>
                  <select 
                    value={u.role}
                    onChange={(e) => updateRole.mutate({ id: u.id, role: e.target.value })}
                    disabled={updateRole.isPending}
                    style={{ padding: '0.25rem' }}
                  >
                    <option value="CUSTOMER">Customer</option>
                    <option value="HALL_MANAGER">Hall Manager</option>
                    <option value="ADMIN">Admin</option>
                  </select>
                </td>
                <td>
                  <span className={`badge ${u.disabled ? 'badge-danger' : 'badge-success'}`}>
                    {u.disabled ? 'Disabled' : 'Active'}
                  </span>
                </td>
                <td>
                  {!u.disabled && (
                    <button 
                      className="btn-small secondary text-danger"
                      onClick={() => {
                        if (confirm('Are you sure you want to disable this user?')) {
                          disableUser.mutate(u.id);
                        }
                      }}
                      disabled={disableUser.isPending}
                    >
                      Disable
                    </button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
