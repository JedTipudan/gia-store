import { useEffect, useState } from 'react';
import { foodApi } from '../../api/services';
import { formatPeso } from '../../utils';
import Modal from '../../components/Modal';
import { Plus, Pencil, Trash2, ShoppingBasket } from 'lucide-react';
import toast from 'react-hot-toast';

const EMPTY = { name: '', description: '', category: '', price: '', stock: 0, imageUrl: '', active: true };

export default function FoodPage() {
  const [items, setItems] = useState([]);
  const [modal, setModal] = useState(null); // null | 'add' | 'edit'
  const [form, setForm] = useState(EMPTY);
  const [editId, setEditId] = useState(null);

  const load = () => foodApi.getAll().then(r => setItems(r.data));
  useEffect(() => { load(); }, []);

  const openAdd = () => { setForm(EMPTY); setEditId(null); setModal('form'); };
  const openEdit = (item) => {
    setForm({ ...item, price: item.price.toString(), stock: item.stock.toString() });
    setEditId(item.id);
    setModal('form');
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    const payload = { ...form, price: parseFloat(form.price), stock: parseInt(form.stock) };
    try {
      if (editId) {
        await foodApi.update(editId, payload);
        toast.success('Food item updated');
      } else {
        await foodApi.create(payload);
        toast.success('Food item added');
      }
      setModal(null);
      load();
    } catch {
      toast.error('Failed to save food item');
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Deactivate this item?')) return;
    try {
      await foodApi.delete(id);
      toast.success('Item deactivated');
      load();
    } catch {
      toast.error('Failed to delete');
    }
  };

  const categories = [...new Set(items.map(i => i.category).filter(Boolean))];

  return (
    <div>
      <div className="page-header">
        <h2>Food Items</h2>
        <button className="btn btn-primary" onClick={openAdd}>
          <Plus size={16} /> Add Item
        </button>
      </div>

      <div className="card">
        {items.length === 0 ? (
          <div className="empty-state">
            <ShoppingBasket size={48} />
            <p>No food items yet. Add your first item!</p>
          </div>
        ) : (
          <div className="table-wrapper">
            <table>
              <thead>
                <tr>
                  <th>Name</th>
                  <th>Category</th>
                  <th>Price</th>
                  <th>Stock</th>
                  <th>Status</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {items.map(item => (
                  <tr key={item.id}>
                    <td>
                      <div className="fw-600">{item.name}</div>
                      {item.description && <div className="text-muted" style={{ fontSize: 12 }}>{item.description}</div>}
                    </td>
                    <td>{item.category || '—'}</td>
                    <td className="fw-600 text-green">{formatPeso(item.price)}</td>
                    <td>{item.stock}</td>
                    <td>
                      <span className={`badge ${item.active ? 'badge-green' : 'badge-red'}`}>
                        {item.active ? 'Active' : 'Inactive'}
                      </span>
                    </td>
                    <td>
                      <div className="flex gap-2">
                        <button className="btn btn-outline btn-sm" onClick={() => openEdit(item)}>
                          <Pencil size={13} />
                        </button>
                        <button className="btn btn-danger btn-sm" onClick={() => handleDelete(item.id)}>
                          <Trash2 size={13} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {modal === 'form' && (
        <Modal title={editId ? 'Edit Food Item' : 'Add Food Item'} onClose={() => setModal(null)}>
          <form onSubmit={handleSubmit}>
            <div className="form-group">
              <label>Name *</label>
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
                <label>Category</label>
                <input className="form-control" value={form.category}
                  list="categories"
                  onChange={e => setForm({ ...form, category: e.target.value })} />
                <datalist id="categories">
                  {categories.map(c => <option key={c} value={c} />)}
                </datalist>
              </div>
              <div className="form-group">
                <label>Price (₱) *</label>
                <input className="form-control" type="number" step="0.01" min="0"
                  value={form.price} required
                  onChange={e => setForm({ ...form, price: e.target.value })} />
              </div>
            </div>
            <div className="grid-2">
              <div className="form-group">
                <label>Stock</label>
                <input className="form-control" type="number" min="0"
                  value={form.stock}
                  onChange={e => setForm({ ...form, stock: e.target.value })} />
              </div>
              <div className="form-group">
                <label>Status</label>
                <select className="form-control" value={form.active}
                  onChange={e => setForm({ ...form, active: e.target.value === 'true' })}>
                  <option value="true">Active</option>
                  <option value="false">Inactive</option>
                </select>
              </div>
            </div>
            <div className="form-group">
              <label>Image URL</label>
              <input className="form-control" value={form.imageUrl}
                onChange={e => setForm({ ...form, imageUrl: e.target.value })} />
            </div>
            <div className="flex gap-2" style={{ justifyContent: 'flex-end' }}>
              <button type="button" className="btn btn-outline" onClick={() => setModal(null)}>Cancel</button>
              <button type="submit" className="btn btn-primary">
                {editId ? 'Update' : 'Add Item'}
              </button>
            </div>
          </form>
        </Modal>
      )}
    </div>
  );
}
