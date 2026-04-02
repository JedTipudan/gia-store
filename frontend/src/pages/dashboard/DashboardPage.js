import { useEffect, useState } from 'react';
import { dashboardApi } from '../../api/services';
import { formatPeso } from '../../utils';
import { ShoppingBasket, Users, Package, CreditCard, TrendingUp, AlertCircle } from 'lucide-react';

const StatCard = ({ label, value, icon: Icon, color, bg }) => (
  <div className="stat-card">
    <div className="stat-icon" style={{ background: bg }}>
      <Icon size={20} color={color} />
    </div>
    <div className="stat-label">{label}</div>
    <div className="stat-value" style={{ color }}>{value}</div>
  </div>
);

export default function DashboardPage() {
  const [data, setData] = useState(null);

  useEffect(() => {
    dashboardApi.getSummary().then(r => setData(r.data)).catch(() => {});
  }, []);

  if (!data) return <div className="empty-state">Loading dashboard...</div>;

  const collectionRate = data.totalPayments > 0
    ? Math.round(((data.totalPayments - data.unpaidPayments) / data.totalPayments) * 100)
    : 0;

  return (
    <div>
      <div className="page-header">
        <h2>Dashboard</h2>
        <span className="text-muted">Overview of your store</span>
      </div>

      <div className="grid-4" style={{ marginBottom: '1.5rem' }}>
        <StatCard label="Food Items" value={data.totalFoodItems}
          icon={ShoppingBasket} color="#16a34a" bg="#dcfce7" />
        <StatCard label="Total Members" value={data.totalMembers}
          icon={Users} color="#2563eb" bg="#dbeafe" />
        <StatCard label="Active Members" value={data.activeMembers}
          icon={Package} color="#d97706" bg="#fef3c7" />
        <StatCard label="Packages" value={data.totalPackages}
          icon={Package} color="#7c3aed" bg="#ede9fe" />
      </div>

      <div className="grid-2">
        <div className="card">
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
            <TrendingUp size={18} color="#16a34a" />
            <h3 style={{ fontSize: 15, fontWeight: 600 }}>Total Collected</h3>
          </div>
          <div style={{ fontSize: 32, fontWeight: 700, color: '#16a34a' }}>
            {formatPeso(data.totalCollected)}
          </div>
          <div className="text-muted mt-1">
            {data.totalPayments - data.unpaidPayments} of {data.totalPayments} payments collected
          </div>
          <div style={{ marginTop: 12, background: '#f1f5f9', borderRadius: 9999, height: 8 }}>
            <div style={{
              width: `${collectionRate}%`, height: '100%',
              background: '#16a34a', borderRadius: 9999, transition: 'width 0.5s'
            }} />
          </div>
          <div className="text-muted mt-1" style={{ fontSize: 12 }}>{collectionRate}% collection rate</div>
        </div>

        <div className="card">
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
            <AlertCircle size={18} color="#dc2626" />
            <h3 style={{ fontSize: 15, fontWeight: 600 }}>Pending Payments</h3>
          </div>
          <div style={{ fontSize: 32, fontWeight: 700, color: '#dc2626' }}>
            {data.unpaidPayments}
          </div>
          <div className="text-muted mt-1">payments awaiting collection</div>
          <div style={{ marginTop: 16 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
              <span className="text-muted" style={{ fontSize: 12 }}>Paid</span>
              <span style={{ fontSize: 12, fontWeight: 600, color: '#16a34a' }}>
                {data.totalPayments - data.unpaidPayments}
              </span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span className="text-muted" style={{ fontSize: 12 }}>Unpaid</span>
              <span style={{ fontSize: 12, fontWeight: 600, color: '#dc2626' }}>
                {data.unpaidPayments}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
