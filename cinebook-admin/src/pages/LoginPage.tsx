import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../lib/auth';

export default function LoginPage() {
  const { requestOtp, login } = useAuth();
  const navigate = useNavigate();
  const [phone, setPhone] = useState('');
  const [otp, setOtp] = useState('');
  const [step, setStep] = useState<'phone' | 'otp'>('phone');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleRequestOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await requestOtp(phone);
      setStep('otp');
    } catch (err: any) {
      setError(err.response?.data?.error?.message || 'Failed to send OTP');
    } finally { setLoading(false); }
  };

  const handleVerify = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await login(phone, otp);
      navigate('/users', { replace: true });
    } catch (err: any) {
      setError(err.message || err.response?.data?.error?.message || 'Login failed');
    } finally { setLoading(false); }
  };

  return (
    <div className="login-page">
      <div className="login-card">
        <h1>CineBook Admin</h1>
        <p className="login-subtitle">Sign in with your admin credentials</p>
        {error && <div className="error-banner">{error}</div>}
        {step === 'phone' ? (
          <form onSubmit={handleRequestOtp}>
            <label htmlFor="phone">Phone Number</label>
            <input id="phone" type="tel" value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="+91XXXXXXXXXX" required />
            <button type="submit" disabled={loading}>{loading ? 'Sending…' : 'Request OTP'}</button>
          </form>
        ) : (
          <form onSubmit={handleVerify}>
            <label htmlFor="otp">Enter OTP</label>
            <input id="otp" type="text" value={otp} onChange={(e) => setOtp(e.target.value)} placeholder="123456" required />
            <button type="submit" disabled={loading}>{loading ? 'Verifying…' : 'Sign In'}</button>
            <button type="button" className="secondary" onClick={() => setStep('phone')}>Back</button>
          </form>
        )}
      </div>
    </div>
  );
}
