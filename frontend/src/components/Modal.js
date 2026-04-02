import { X } from 'lucide-react';

export default function Modal({ title, onClose, children }) {
  return (
    <div className="modal-overlay" onClick={e => e.target === e.currentTarget && onClose()}>
      <div className="modal">
        <div className="modal-header">
          <h3>{title}</h3>
          <button className="btn btn-outline btn-sm" onClick={onClose}><X size={14} /></button>
        </div>
        {children}
      </div>
    </div>
  );
}
