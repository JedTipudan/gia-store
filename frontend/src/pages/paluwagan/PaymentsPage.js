import { useEffect, useState, useCallback } from 'react';
import { paymentApi, memberApi, receiptApi } from '../../api/services';
import { formatPeso, formatDate } from '../../utils';
import { CheckCircle, XCircle, Download, FileText, Filter } from 'lucide-react';
import { useSearchParams } from 'react-router-dom';
import toast from 'react-hot-toast';

export default function PaymentsPage() {
  const [payments, setPayments] = useState([]);
  const [members, setMembers] = useState([]);
  const [filter, setFilter] = useState('ALL'); // ALL | PAID | UNPAID
  const [memberFilter, setMemberFilter] = useState('');
  const [searchParams] = useSearchParams();

  const load = useCallback(() => {
    const memberId = searchParams.get('member');
    if (memberId) {
      setMemberFilter(memberId);
      paymentApi.getByMember(memberId).then(r => setPayments(r.data));
    } else {
      paymentApi.getAll().then(r => setPayments(r.data));
    }
    memberApi.getAll().then(r => setMembers(r.data));
  }, [searchParams]);

  useEffect(() => { load(); }, [load]);

  const handleMemberFilter = (memberId) => {
    setMemberFilter(memberId);
    if (memberId) paymentApi.getByMember(memberId).then(r => setPayments(r.data));
    else paymentApi.getAll().then(r => setPayments(r.data));
  };

  const markPaid = async (id) => {
    try { await paymentApi.markPaid(id); toast.success('Payment marked as paid'); load(); }
    catch { toast.error('Failed to update payment'); }
  };

  const markUnpaid = async (id) => {
    try { await paymentApi.markUnpaid(id); toast.success('Payment marked as unpaid'); load(); }
    catch { toast.error('Failed to update payment'); }
  };

  const downloadReceipt = async (payment) => {
    try {
      const res = await receiptApi.downloadPdf(payment.id);
      const url = URL.createObjectURL(new Blob([res.data], { type: 'application/pdf' }));
      const a = document.createElement('a');
      a.href = url;
      a.download = `receipt-${payment.receiptNumber || payment.id}.pdf`;
      a.click();
      URL.revokeObjectURL(url);
      toast.success('Receipt downloaded');
    } catch { toast.error('Failed to download receipt'); }
  };

  const filtered = payments.filter(p => {
    if (filter === 'PAID') return p.paid;
    if (filter === 'UNPAID') return !p.paid;
    return true;
  });

  const paidCount = payments.filter(p => p.paid).length;
  const unpaidCount = payments.filter(p => !p.paid).length;

  return (
    <div>
      <div className="page-header">
        <h2>Payments</h2>
        <div className="flex gap-2 items-center">
          <span className="badge badge-green">{paidCount} Paid</span>
          <span className="badge badge-red">{unpaidCount} Unpaid</span>
        </div>
      </div>

      {/* Filters */}
      <div className="card" style={{ marginBottom: '1rem', padding: '1rem' }}>
        <div className="flex gap-2 items-center" style={{ flexWrap: 'wrap' }}>
          <Filter size={16} className="text-muted" />
          <select className="form-control" style={{ width: 'auto', minWidth: 160 }}
            value={memberFilter} onChange={e => handleMemberFilter(e.target.value)}>
            <option value="">All Members</option>
            {members.map(m => <option key={m.id} value={m.id}>{m.fullName}</option>)}
          </select>
          {['ALL', 'PAID', 'UNPAID'].map(f => (
            <button key={f} className={`btn btn-sm ${filter === f ? 'btn-primary' : 'btn-outline'}`}
              onClick={() => setFilter(f)}>{f}</button>
          ))}
        </div>
      </div>

      <div className="card">
        {filtered.length === 0 ? (
          <div className="empty-state"><FileText size={48} /><p>No payments found.</p></div>
        ) : (
          <div className="table-wrapper">
            <table>
              <thead>
                <tr><th>Member</th><th>Package</th><th>Week</th><th>Amount</th><th>Due Date</th><th>Paid On</th><th>Receipt</th><th>Status</th><th>Actions</th></tr>
              </thead>
              <tbody>
                {filtered.map(p => (
                  <tr key={p.id}>
                    <td className="fw-600">{p.member?.fullName}</td>
                    <td className="text-muted">{p.member?.paluwaganPackage?.name}</td>
                    <td>Week {p.weekNumber}</td>
                    <td className="fw-600 text-green">{formatPeso(p.amount)}</td>
                    <td>{formatDate(p.dueDate)}</td>
                    <td>{p.paidAt ? formatDate(p.paidAt) : '—'}</td>
                    <td style={{ fontSize: 12 }}>{p.receiptNumber || '—'}</td>
                    <td>
                      <span className={`badge ${p.paid ? 'badge-green' : 'badge-red'}`}>
                        {p.paid ? 'Paid' : 'Unpaid'}
                      </span>
                    </td>
                    <td>
                      <div className="flex gap-2">
                        {!p.paid ? (
                          <button className="btn btn-primary btn-sm" onClick={() => markPaid(p.id)}>
                            <CheckCircle size={13} /> Pay
                          </button>
                        ) : (
                          <>
                            <button className="btn btn-outline btn-sm" onClick={() => markUnpaid(p.id)}>
                              <XCircle size={13} /> Unpay
                            </button>
                            <button className="btn btn-outline btn-sm" onClick={() => downloadReceipt(p)}>
                              <Download size={13} /> PDF
                            </button>
                          </>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
