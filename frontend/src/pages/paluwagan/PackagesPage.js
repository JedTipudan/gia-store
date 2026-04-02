import { useEffect, useState } from 'react';
import { packageApi } from '../../api/services';
import { formatPeso } from '../../utils';
import Modal from '../../components/Modal';
import { Plus, Pencil, Trash2, Package } from 'lucide-react';
import toast from 'react-hot-toast';

const EMPTY = { name: '', description: '', weeklyAmount: '', durationWeeks: '', active: true };

export default function PackagesPage() {
  const [packages, setPackages] = useState([]);
  const [modal, setModal] = useState(false);
  const [form, setForm] = useState(EMPTY);
  const [editId, setEditId] = useState(null);

  const load = () => packageApi.getAll().then(r => setPackages(r.data));
  useEffect(() => { load(); }, []);

  const openAdd = () => { setForm(EMPTY); setEditId(null); setModal(true); };
  const openEdit = (pkg) => {
    setForm({ ...pkg, weeklyAmount: pkg.weeklyAmount.toString(), durationWeeks: pkg.durationWeeks.toString() });
    setEditId(pkg.id);
    setModal(true);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    const payload = { ...form, weeklyAmount: parseFloat(form.weeklyAmount), durationWeeks: parseInt(form.durationWeeks) };
    try {
      if (editId) { await packageApi.update(editId, payload); toast.success('Package updated'); }
      else { await packageApi.create(payload); toast.success('Package created'); }
      setModal(false);
      load();
    } catch { toast.error('Failed to save package'); }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Deactivate this package?')) return;
    try { await packageApi.delete(id); toast.success('Package deactivated'); load(); }
    catch { toast.error('Failed to delete'); }
  };

  return (
    <div>
      <div className="page-header">
        <h2>Paluwagan Packages</h2>
        <button className="btn btn-primary" onClick={openAdd}><Plus size={16} /> Add Package</button>
      </div>

      <div className="card">
        {packages.length === 0 ? (
          <div className="empty-state"><Package size={48} /><p>No packages yet.</p></div>
        ) : (
          <div className="table-wrapper">
            <table>
              <thead>
                <tr><th>Name</th><th>Weekly Amount</th><th>Duration</th><th>Total Value</th><th>Status</th><th>Actions</th></tr>
              </thead>
              <tbody>
                {packages.map(pkg => (
                  <tr key={pkg.id}>
                    <td>
                      <div className="fw-600">{pkg.name}</div>
                      {pkg.description && <div className="text-muted" style={{ fontSize: 12 }}>{pkg.description}</div>}
                    </td>
                    <td className="fw-600 text-green">{formatPeso(pkg.weeklyAmount)}/week</td>
                    <td>{pkg.durationWeeks} weeks</td>
                    <td className="fw-600">{formatPeso(pkg.weeklyAmount * pkg.durationWeeks)}</td>
                    <td><span className={`badge ${pkg.active ? 'badge-green' : 'badge-red'}`}>{pkg.active ? 'Active' : 'Inactive'}</span></td>
                    <td>
                      <div className="flex gap-2">
                        <button className="btn btn-outline btn-sm" onClick={() => openEdit(pkg)}><Pencil size={13} /></button>
                        <button className="btn btn-danger btn-sm" onClick={() => handleDelete(pkg.id)}><Trash2 size={13} /></button>
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
        <Modal title={editId ? 'Edit Package' : 'Add Package'} onClose={() => setModal(false)}>
          <form onSubmit={handleSubmit}>
            <div className="form-group">
              <label>Package Name *</label>
              <input className="form-control" value={form.name} required
                onChange={e => setForm({ ...form, name: e.target.value })} />
            </div>
            <div className="form-group">
              <label>Description</label>
              <input className="form-control" value={form.description}
                onChange={e => setForm({ ...form, description: e.target.value })} />
            </div>
            <div className="grid-2">
              <div className="form-group">
                <label>Weekly Amount (₱) *</label>
                <input className="form-control" type="number" step="0.01" min="1"
                  value={form.weeklyAmount} required
                  onChange={e => setForm({ ...form, weeklyAmount: e.target.value })} />
              </div>
              <div className="form-group">
                <label>Duration (weeks) *</label>
                <input className="form-control" type="number" min="1"
                  value={form.durationWeeks} required
                  onChange={e => setForm({ ...form, durationWeeks: e.target.value })} />
              </div>
            </div>
            {form.weeklyAmount && form.durationWeeks && (
              <div className="card" style={{ background: '#f0fdf4', marginBottom: '1rem', padding: '0.75rem' }}>
                <span className="text-muted" style={{ fontSize: 12 }}>Total Package Value: </span>
                <span className="fw-600 text-green">{formatPeso(parseFloat(form.weeklyAmount) * parseInt(form.durationWeeks))}</span>
              </div>
            )}
            <div className="flex gap-2" style={{ justifyContent: 'flex-end' }}>
              <button type="button" className="btn btn-outline" onClick={() => setModal(false)}>Cancel</button>
              <button type="submit" className="btn btn-primary">{editId ? 'Update' : 'Create'}</button>
            </div>
          </form>
        </Modal>
      )}
    </div>
  );
}
