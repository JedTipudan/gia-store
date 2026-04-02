import { NavLink, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { LayoutDashboard, ShoppingBasket, Users, Package, CreditCard, LogOut, Store } from 'lucide-react';

const links = [
  { to: '/', icon: LayoutDashboard, label: 'Dashboard' },
  { to: '/food', icon: ShoppingBasket, label: 'Food Items' },
  { to: '/packages', icon: Package, label: 'Packages' },
  { to: '/members', icon: Users, label: 'Members' },
  { to: '/payments', icon: CreditCard, label: 'Payments' },
];

export default function Sidebar({ open, onClose }) {
  const { logout, username } = useAuth();
  const navigate = useNavigate();

  const handleLogout = () => { logout(); navigate('/login'); };

  return (
    <>
      {open && <div className="sidebar-overlay" onClick={onClose} />}
      <aside className={`sidebar ${open ? 'open' : ''}`}>
        <div className="sidebar-brand">
          <Store size={22} color="#16a34a" />
          <span>Gia Store</span>
        </div>
        <nav className="sidebar-nav">
          {links.map(({ to, icon: Icon, label }) => (
            <NavLink key={to} to={to} end={to === '/'} className={({ isActive }) =>
              `sidebar-link ${isActive ? 'active' : ''}`} onClick={onClose}>
              <Icon size={18} />
              <span>{label}</span>
            </NavLink>
          ))}
        </nav>
        <div className="sidebar-footer">
          <div className="sidebar-user">
            <div className="sidebar-avatar">{username?.[0]?.toUpperCase()}</div>
            <span>{username}</span>
          </div>
          <button className="btn btn-outline btn-sm" onClick={handleLogout}>
            <LogOut size={14} /> Logout
          </button>
        </div>
      </aside>
    </>
  );
}
