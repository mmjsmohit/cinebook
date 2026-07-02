import { useState, useEffect } from 'react';
import { useQuery } from '@tanstack/react-query';
import { api } from '../lib/api';

interface ActivityLog {
  id: string;
  actorId: string;
  action: string;
  entity: string;
  metadata: any;
  createdAt: string;
}

function timeSince(dateString: string) {
  const date = new Date(dateString);
  const seconds = Math.floor((new Date().getTime() - date.getTime()) / 1000);
  let interval = seconds / 31536000;
  if (interval > 1) return Math.floor(interval) + ' years ago';
  interval = seconds / 2592000;
  if (interval > 1) return Math.floor(interval) + ' months ago';
  interval = seconds / 86400;
  if (interval > 1) return Math.floor(interval) + ' days ago';
  interval = seconds / 3600;
  if (interval > 1) return Math.floor(interval) + ' hours ago';
  interval = seconds / 60;
  if (interval > 1) return Math.floor(interval) + ' minutes ago';
  return Math.floor(seconds) + ' seconds ago';
}

export default function ActivityPage() {
  const [actorId, setActorId] = useState('');
  const [from, setFrom] = useState('');
  const [to, setTo] = useState('');

  // Debounce state to avoid over-fetching
  const [debouncedFilters, setDebouncedFilters] = useState({ actorId, from, to });

  useEffect(() => {
    const handler = setTimeout(() => setDebouncedFilters({ actorId, from, to }), 500);
    return () => clearTimeout(handler);
  }, [actorId, from, to]);

  const { data: logs, isLoading } = useQuery({
    queryKey: ['activity', debouncedFilters],
    queryFn: async () => {
      const params = new URLSearchParams();
      if (debouncedFilters.actorId) params.set('actorId', debouncedFilters.actorId);
      if (debouncedFilters.from) params.set('from', new Date(debouncedFilters.from).toISOString());
      if (debouncedFilters.to) params.set('to', new Date(debouncedFilters.to).toISOString());
      
      const res = await api.get<{ logs: ActivityLog[] }>(`/admin/activity-log?${params.toString()}`);
      return res.data.logs;
    },
  });

  return (
    <div className="page-container">
      <h2>Activity Log</h2>

      <div style={{ background: 'var(--surface)', padding: '1.5rem', borderRadius: 8, marginBottom: '2rem', border: '1px solid var(--border)', display: 'grid', gridTemplateColumns: '1fr 1fr 1fr auto', gap: '1rem', alignItems: 'end' }}>
        <div>
          <label>Actor ID</label>
          <input value={actorId} onChange={e => setActorId(e.target.value)} placeholder="Search by actor..." />
        </div>
        <div>
          <label>From Date</label>
          <input type="datetime-local" value={from} onChange={e => setFrom(e.target.value)} />
        </div>
        <div>
          <label>To Date</label>
          <input type="datetime-local" value={to} onChange={e => setTo(e.target.value)} />
        </div>
        <div>
          <button className="secondary" onClick={() => { setActorId(''); setFrom(''); setTo(''); }}>Clear</button>
        </div>
      </div>

      <div className="table-wrapper">
        <table>
          <thead>
            <tr>
              <th>Time</th>
              <th>Actor</th>
              <th>Action</th>
              <th>Entity</th>
              <th>Metadata</th>
            </tr>
          </thead>
          <tbody>
            {isLoading ? (
              <tr><td colSpan={5} style={{ textAlign: 'center' }}>Loading...</td></tr>
            ) : logs?.length === 0 ? (
              <tr><td colSpan={5} style={{ textAlign: 'center' }}>No activity found.</td></tr>
            ) : logs?.map((log) => (
              <tr key={log.id}>
                <td title={new Date(log.createdAt).toLocaleString()} style={{ whiteSpace: 'nowrap' }}>
                  {timeSince(log.createdAt)}
                </td>
                <td><span className="text-sm font-mono">{log.actorId.slice(-8)}</span></td>
                <td><span className="badge secondary">{log.action}</span></td>
                <td>{log.entity}</td>
                <td>
                  <div style={{ maxWidth: 300, maxHeight: 100, overflow: 'auto', background: 'var(--bg-dark)', padding: '0.5rem', borderRadius: 4, fontSize: '0.75rem', fontFamily: 'monospace' }}>
                    {log.metadata ? JSON.stringify(log.metadata, null, 2) : '-'}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
