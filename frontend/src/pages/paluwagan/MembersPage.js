import { useEffect, useState } from 'react';
import { memberApi, packageApi } from '../../api/services';
import { formatDate, formatPeso } from '../../utils';
import Modal from '../../components/Modal';
import { Plus, Pencil, Users, Eye } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import toast from 'react-hot-toast';

const EMPTY = { fullName: '', phone: '', address: '', paluwaganPackage: { id: '' }, startDate: '', status: 'ACTIVE' };

export default function MembersPage() {
  const [members, setMembers] = useState([]);
  const [packages, setPackages] = useState([]);
  const [modal, setModal] = useState(false);
  const [form, setForm] = useState(EMPTY);
  const [editId, setEditId] = useState(null);
  const navigate = useNavigate();

  const load = () => {
    memberApi.getAll().then(r => setMembers(r.data));
    packageApi.getAll().then(r => setPackages(r.data));
  };
  useEffect(() => { load(); }, []);

  const openAdd = () => { setForm(EMPTY); setEditId(null); setModal(true); };
  const openEdit = (m) => {
    setForm({ ...m, paluwaganPackage: { id: m.paluwaganPackage.id }, startDate: m.startDate });
    setEditId(m.id);
    setModal(true);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    const payload = { ...form, paluwaganPackage: { id: parseInt(form.paluwaganPackage.id) } };
    try {
      if (editId) { await memberApi.update(editId, payload); toast.success('Member updated'); }
      else { await memberApi.create(payload); toast.success('Member added & payment schedule generated'); }
      setModal(false);
      load();
    } catch { toast.error('Failed to save member'); }
  };

  const statusColors = { ACTIVE: 'badge-green', COMPLETED: 'badge-blue', DROPPED: 'badge-red' };

  return (
    <div>
      <div className="page-header">
        <h2>Members</h2>
        <button className="btn btn-primary" onClick={openAdd}><Plus size={16} /> Add Member</button>
      </div>

      <div className="card">
        {members.length === 0 ? (
          <div className="empty-state"><Users size={48} /><p>No members yet.</p></div>
        ) : (
          <div className="table-wrapper">
            <table>
              <thead>
                <tr><th>Name</th><th>Package</th><th>Weekly</th><th>Start Date</th><th>Status</th><th>Actions</th></tr>
              </thead>
              <tbody>
                {members.map(m => (
                  <tr key={m.id}>
                    <td>
                      <div className="fw-600">{m.fullName}</div>
                      {m.phone && <div className="text-muted" style={{ fontSize: 12 }}>{m.phone}</div>}
                    </td>
                    <td>{m.paluwaganPackage?.name}</td>
                    <td className="text-green fw-600">{formatPeso(m.paluwaganPackage?.weeklyAmount)}</td>
                    <td>{formatDate(m.startDate)}</td>
                    <td><span className={`badge ${statusColors[m.status] || 'badge-yellow'}`}>{m.status}</span></td>
                    <td>
                      <div className="flex gap-2">
                        <button className="btn btn-outline btn-sm" onClick={() => navigate(`/payments?member=${m.id}`)}>
                          <Eye size={13} /> Payments
                        </button>
                        <button className="btn btn-outline btn-sm" onClick={() => openEdit(m)}><Pencil size={13} /></button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {modal && (
        <Modal title={editId ? 'Edit Member' : 'Add Member'} onClose={() => setModal(false)}>
          <form onSubmit={handleSubmit}>
            <div className="form-group">
              <label>Full Name *</label>
              <input className="form-control" value={form.fullName} required
                onChange={e => setForm({ ...form, fullName: e.target.value })} />
            </div>
            <div className="grid-2">
              <div className="form-group">
                <label>Phone</label>
                <input className="form-control" value={form.phone}
                  onChange={e => setForm({ ...form, phone: e.target.value })} />
              </div>
              <div className="form-group">
                <label>Status</label>
                <select className="form-control" value={form.status}
                  onChange={e => setForm({ ...form, status: e.target.value })}>
                  <option>ACTIVE</option>
                  <option>COMPLETED</option>
                  <option>DROPPED</option>
                </select>
              </div>
            </div>
            <div className="form-group">
              <label>Address</label>
              <input className="form-control" value={form.address}
                onChange={e => setForm({ ...form, address: e.target.value })} />
            </div>
            {!editId && (
              <div className="grid-2">
                <div className="form-group">
                  <label>Package *</label>
                  <select className="form-control" value={form.paluwaganPackage.id} required
                    onChange={e => setForm({ ...form, paluwaganPackage: { id: e.target.value } })}>
                    <option value="">Select package</option>
                    {packages.filter(p => p.active).map(p => (
                      <option key={p.id} value={p.id}>{p.name} — {formatPeso(p.weeklyAmount)}/wk</option>
                    ))}
                  </select>
                </div>
                <div className="form-group">
                  <label>Start Date *</label>
                  <input className="form-control" type="date" value={form.startDate} required
                    onChange={e => setForm({ ...form, startDate: e.target.value })} />
                </div>
              </div>
            )}
            <div className="flex gap-2" style={{ justifyContent: 'flex-end' }}>
              <button type="button" className="btn btn-outline" onClick={() => setModal(false)}>Cancel</button>
              <button type="submit" className="btn btn-primary">{editId ? 'Update' : 'Add Member'}</button>
            </div>
          </form>
        </Modal>
      )}
    </div>
  );
}
