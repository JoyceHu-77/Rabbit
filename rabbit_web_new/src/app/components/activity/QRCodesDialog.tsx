import { useState, useRef, useEffect } from 'react';
import { Dialog, DialogContent, DialogTitle } from '../ui/dialog';
import { Button } from '../ui/button';
import { toast } from 'sonner';
import { X, Upload, Image as ImageIcon, QrCode, Trash2 } from 'lucide-react';

export interface PaymentQRCode {
  wechat: string | null;
  alipay: string | null;
}

const loadQRCodes = (): PaymentQRCode => {
  try {
    const saved = localStorage.getItem('paymentQRCodes');
    if (saved) return JSON.parse(saved);
  } catch (e) {
    console.error('Failed to load QR codes:', e);
  }
  return { wechat: null, alipay: null };
};

const saveQRCodes = (codes: PaymentQRCode) => {
  try {
    localStorage.setItem('paymentQRCodes', JSON.stringify(codes));
  } catch (e) {
    console.error('Failed to save QR codes:', e);
  }
};

interface QRCodesDialogProps {
  open: boolean;
  onClose: () => void;
}

// 导出获取二维码的函数供其他组件使用
export const getPaymentQRCodes = (): PaymentQRCode => loadQRCodes();

export default function QRCodesDialog({ open, onClose }: QRCodesDialogProps) {
  const [qrCodes, setQRCodes] = useState<PaymentQRCode>({ wechat: null, alipay: null });
  const [uploading, setUploading] = useState<'wechat' | 'alipay' | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (open) {
      setQRCodes(loadQRCodes());
    }
  }, [open]);

  const handleUpload = (e: React.ChangeEvent<HTMLInputElement>, type: 'wechat' | 'alipay') => {
    const file = e.target.files?.[0];
    if (!file) return;

    setUploading(type);
    const reader = new FileReader();
    reader.onloadend = () => {
      const updated = { ...qrCodes, [type]: reader.result as string };
      setQRCodes(updated);
      saveQRCodes(updated);
      setUploading(null);
      toast.success(`${type === 'wechat' ? '微信' : '支付宝'}收款码上传成功`);
    };
    reader.readAsDataURL(file);
  };

  const handleDelete = (type: 'wechat' | 'alipay') => {
    const updated = { ...qrCodes, [type]: null };
    setQRCodes(updated);
    saveQRCodes(updated);
    toast.success(`${type === 'wechat' ? '微信' : '支付宝'}收款码已删除`);
  };

  const QRCodeCard = ({
    type,
    label,
    color,
  }: {
    type: 'wechat' | 'alipay';
    label: string;
    color: 'green' | 'blue';
  }) => {
    const code = qrCodes[type];
    const colorClass = color === 'green' ? 'border-green-200 bg-green-50' : 'border-blue-200 bg-blue-50';
    const iconBgClass = color === 'green' ? 'bg-green-500' : 'bg-blue-500';
    const textClass = color === 'green' ? 'text-green-600' : 'text-blue-600';
    const hoverClass = color === 'green' ? 'hover:border-green-400 hover:bg-green-100' : 'hover:border-blue-400 hover:bg-blue-100';

    return (
      <div className={`rounded-xl border-2 ${colorClass} p-4 transition-colors`}>
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-2">
            <div className={`w-8 h-8 ${iconBgClass} rounded-lg flex items-center justify-center`}>
              {type === 'wechat' ? (
                <svg viewBox="0 0 24 24" className="w-5 h-5 text-white" fill="currentColor">
                  <path d="M8.691 2.188C3.891 2.188 0 5.476 0 9.53c0 2.212 1.17 4.203 3.002 5.55a.59.59 0 0 1 .213.665l-.39 1.48c-.019.07-.048.141-.048.213 0 .163.13.295.29.295a.326.326 0 0 0 .167-.054l1.903-1.114a.864.864 0 0 1 .717-.098 10.16 10.16 0 0 0 2.837.403c.276 0 .543-.027.811-.05-.857-2.578.157-4.972 1.932-6.446 1.703-1.415 3.882-1.98 5.853-1.838-.576-3.583-4.196-6.348-8.596-6.348zM5.785 5.991c.642 0 1.162.529 1.162 1.18a1.17 1.17 0 0 1-1.162 1.178A1.17 1.17 0 0 1 4.623 7.17c0-.651.52-1.18 1.162-1.18zm5.813 0c.642 0 1.162.529 1.162 1.18a1.17 1.17 0 0 1-1.162 1.178 1.17 1.17 0 0 1-1.162-1.178c0-.651.52-1.18 1.162-1.18zm5.34 2.867c-1.797-.052-3.746.512-5.28 1.786-1.72 1.428-2.687 3.72-1.78 6.22.942 2.453 3.666 4.229 6.884 4.229.826 0 1.622-.12 2.361-.336a.722.722 0 0 1 .598.082l1.584.926a.272.272 0 0 0 .14.047c.134 0 .24-.111.24-.247 0-.06-.023-.12-.038-.177l-.327-1.233a.582.582 0 0 1-.023-.156.49.49 0 0 1 .201-.398C23.024 18.48 24 16.82 24 14.98c0-3.21-2.931-5.837-6.656-6.088V8.89c-.135-.01-.269-.03-.406-.03zm-1.984 2.133c.535 0 .969.44.969.982a.976.976 0 0 1-.969.983.976.976 0 0 1-.969-.983c0-.542.434-.982.97-.982zm4.842 0c.535 0 .969.44.969.982a.976.976 0 0 1-.969.983.976.976 0 0 1-.969-.983c0-.542.434-.982.969-.982z"/>
                </svg>
              ) : (
                <svg viewBox="0 0 24 24" className="w-5 h-5 text-white" fill="currentColor">
                  <path d="M21.88 8.05c.24-.8.2-1.47.2-2.38 0-1.32-1.1-2.67-3.08-2.67-1.95 0-4.03.95-5.63 2.45C11.76 4.1 10.06 3.05 8.1 3.05c-1.98 0-3.08 1.35-3.08 2.67 0 .91-.03 1.58.22 2.38-1.34.64-2.2 1.85-2.2 3.32 0 1.97 1.97 3.28 5.2 3.28 1.28 0 2.5-.3 3.6-.88v.04c0 .1 0 .2.05.3.1.2.18.43.28.63.3.6.6 1.2.95 1.75.7 1.1 1.5 2.15 2.45 2.95 1.9 1.6 4.15 2.4 6.6 2.4 2.95 0 5.35-1.25 6.85-3.7.95-1.55 1.3-3.35 1.3-5.6 0-2.5-1.05-4.75-2.85-6.3z"/>
                </svg>
              )}
            </div>
            <span className={`font-semibold ${textClass}`}>{label}</span>
          </div>
          {code && (
            <button
              onClick={() => handleDelete(type)}
              className="p-1.5 text-gray-400 hover:text-red-500 hover:bg-red-50 rounded-full transition-colors"
              title="删除"
            >
              <Trash2 size={16} />
            </button>
          )}
        </div>

        {code ? (
          <div className="relative rounded-lg overflow-hidden bg-white">
            <img
              src={code}
              alt={`${label}收款码`}
              className="w-full aspect-square object-contain"
            />
            <label className="absolute inset-0 bg-black/0 hover:bg-black/20 flex items-center justify-center cursor-pointer transition-colors">
              <input
                type="file"
                accept="image/*"
                onChange={(e) => handleUpload(e, type)}
                className="hidden"
                ref={uploading === type ? fileInputRef : undefined}
              />
              <span className="opacity-0 hover:opacity-100 bg-white/90 px-3 py-1.5 rounded-full text-sm font-medium text-gray-700 transition-opacity">
                重新上传
              </span>
            </label>
          </div>
        ) : (
          <label className={`block border-2 border-dashed rounded-xl p-8 text-center cursor-pointer transition-colors ${hoverClass}`}>
            <input
              type="file"
              accept="image/*"
              onChange={(e) => handleUpload(e, type)}
              className="hidden"
              ref={fileInputRef}
            />
            {uploading === type ? (
              <div className="text-center">
                <div className="w-12 h-12 border-4 border-current border-t-transparent rounded-full animate-spin mx-auto mb-2" style={{ borderColor: color === 'green' ? '#22c55e' : '#3b82f6', borderTopColor: 'transparent' }} />
                <p className="text-sm text-gray-500">上传中...</p>
              </div>
            ) : (
              <>
                <QrCode size={32} className={`mx-auto ${textClass} mb-2`} />
                <p className="text-sm text-gray-600">点击上传{label}收款码</p>
              </>
            )}
          </label>
        )}
      </div>
    );
  };

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-md" showClose={false}>
        <DialogTitle className="text-xl font-bold text-gray-800 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <QrCode size={24} className="text-pink-600" />
            <span>管理收款二维码</span>
          </div>
          <button onClick={onClose} className="p-1 hover:bg-gray-100 rounded">
            <X size={20} />
          </button>
        </DialogTitle>

        <div className="space-y-4 py-4 max-h-[60vh] overflow-y-auto pr-1">
          <p className="text-sm text-gray-500">
            上传微信和支付宝收款二维码，用户购买时将展示对应的收款码
          </p>

          <div className="grid grid-cols-2 gap-4">
            <QRCodeCard type="wechat" label="微信支付" color="green" />
            <QRCodeCard type="alipay" label="支付宝" color="blue" />
          </div>

          <div className="bg-amber-50 border border-amber-200 rounded-lg p-3">
            <p className="text-xs text-amber-800">
              💡 提示：请上传清晰的收款二维码图片，确保用户能够正常扫码支付
            </p>
          </div>
        </div>

        <div className="flex justify-end pt-4 border-t">
          <Button onClick={onClose} className="bg-gradient-to-r from-pink-500 to-orange-500 hover:from-pink-600 hover:to-orange-600">
            完成
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}
