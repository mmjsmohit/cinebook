import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { api } from '../lib/api';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';

interface ReportData {
  period: string;
  count: number;
  revenue: number;
}

interface ReportResponse {
  range: string;
  totalBookings: number;
  totalRevenue: number;
  data: ReportData[];
}

export default function ReportsPage() {
  const [range, setRange] = useState<'daily' | 'weekly' | 'monthly'>('daily');

  const { data, isLoading, error } = useQuery({
    queryKey: ['reports', range],
    queryFn: async () => {
      const res = await api.get<{ report: ReportResponse }>(`/admin/reports?range=${range}`);
      // convert revenue from paise to INR
      res.data.report.data = res.data.report.data.map(d => ({
        ...d,
        revenue: d.revenue / 100
      }));
      res.data.report.totalRevenue = res.data.report.totalRevenue / 100;
      return res.data.report;
    },
  });

  return (
    <div className="page-container">
      <h2>Reports Dashboard</h2>

      <div className="flex-row" style={{ marginBottom: '2rem', gap: '1rem' }}>
        <button 
          className={range === 'daily' ? '' : 'secondary'} 
          onClick={() => setRange('daily')}
        >Daily</button>
        <button 
          className={range === 'weekly' ? '' : 'secondary'} 
          onClick={() => setRange('weekly')}
        >Weekly</button>
        <button 
          className={range === 'monthly' ? '' : 'secondary'} 
          onClick={() => setRange('monthly')}
        >Monthly</button>
      </div>

      {isLoading ? (
        <div className="loading">Loading reports...</div>
      ) : error ? (
        <div className="error-banner">Failed to load reports</div>
      ) : data ? (
        <>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.5rem', marginBottom: '2rem' }}>
            <div style={{ background: 'var(--surface)', padding: '1.5rem', borderRadius: 8, border: '1px solid var(--border)' }}>
              <div className="text-muted text-sm uppercase">Total Bookings</div>
              <div style={{ fontSize: '2.5rem', fontWeight: 700, marginTop: '0.5rem', color: 'var(--text-main)' }}>
                {data.totalBookings.toLocaleString()}
              </div>
            </div>
            <div style={{ background: 'var(--surface)', padding: '1.5rem', borderRadius: 8, border: '1px solid var(--border)' }}>
              <div className="text-muted text-sm uppercase">Total Revenue (INR)</div>
              <div style={{ fontSize: '2.5rem', fontWeight: 700, marginTop: '0.5rem', color: 'var(--success)' }}>
                ₹{data.totalRevenue.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
              </div>
            </div>
          </div>

          <div style={{ background: 'var(--surface)', padding: '1.5rem', borderRadius: 8, border: '1px solid var(--border)', height: 400 }}>
            <h3 style={{ marginBottom: '1.5rem' }}>Revenue & Bookings ({range})</h3>
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={data.data} margin={{ top: 5, right: 30, left: 20, bottom: 5 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" vertical={false} />
                <XAxis dataKey="period" stroke="var(--text-muted)" tick={{ fill: 'var(--text-muted)' }} />
                <YAxis yAxisId="left" stroke="var(--primary)" tick={{ fill: 'var(--text-muted)' }} />
                <YAxis yAxisId="right" orientation="right" stroke="var(--success)" tick={{ fill: 'var(--text-muted)' }} />
                <Tooltip 
                  contentStyle={{ backgroundColor: 'var(--surface)', borderColor: 'var(--border)', color: 'var(--text-main)' }}
                  itemStyle={{ color: 'var(--text-main)' }}
                />
                <Legend />
                <Bar yAxisId="left" dataKey="count" name="Bookings" fill="var(--primary)" radius={[4, 4, 0, 0]} />
                <Bar yAxisId="right" dataKey="revenue" name="Revenue (₹)" fill="var(--success)" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </>
      ) : null}
    </div>
  );
}
