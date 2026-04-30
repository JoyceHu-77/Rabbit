import { useState, useEffect } from 'react';
import { Dialog, DialogContent, DialogTitle, DialogDescription } from '../ui/dialog';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { toast } from 'sonner';
import { X, Coins, ShoppingBag } from 'lucide-react';
import { getPaymentQRCodes } from './QRCodesDialog';
import { addCloudAdoptOrder } from '../profile/OrdersDialog';

interface CloudAdoptDialogProps {
  open: boolean;
  onClose: () => void;
  rabbitName: string;
  rabbitImage: string;
  onSuccess?: (rabbitName: string) => void;
}

export default function CloudAdoptDialog({
  open,
  onClose,
  rabbitName,
  rabbitImage,
  onSuccess,
}: CloudAdoptDialogProps) {
  const [amount, setAmount] = useState('');
  const [paymentMethod, setPaymentMethod] = useState<'wechat' | 'alipay'>('wechat');
  const [qrCodes, setQRCodes] = useState<{ wechat: string | null; alipay: string | null }>({ wechat: null, alipay: null });
  const [step, setStep] = useState<'input' | 'pay'>('input');

  useEffect(() => {
    if (open) {
      setQRCodes(getPaymentQRCodes());
      setStep('input');
      setAmount('');
    }
  }, [open]);

  const cloudCoins = amount && parseFloat(amount) > 0 ? Math.floor(parseFloat(amount) * 0.1) : 0;
  const currentQRCode = paymentMethod === 'wechat' ? qrCodes.wechat : qrCodes.alipay;
  const hasQRCode = !!currentQRCode;
  const quickAmounts = [10, 30, 50, 100];

  const handleNextStep = (e: React.FormEvent) => {
    e.preventDefault();
    const numAmount = parseFloat(amount);
    if (!numAmount || numAmount < 1) {
      toast.error('请输入有效金额', {
        description: '云养金额需大于等于1元',
      });
      return;
    }
    if (!hasQRCode) {
      toast.error('管理员暂未配置收款码', {
        description: '请稍后再试或联系客服',
      });
      return;
    }
    setStep('pay');
  };

  const handleConfirm = () => {
    const numAmount = parseFloat(amount);

    addCloudAdoptOrder({
      rabbitName,
      rabbitImage,
      amount: numAmount,
      cloudCoins,
    });

    toast.success('云养订单已创建！', {
      description: '请前往"我的订单"上传支付凭证，待审核后云养生效',
    });

    if (onSuccess) {
      onSuccess(rabbitName);
    }

    setAmount('');
    setStep('input');
    onClose();
  };

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-md" showClose={false}>
        <DialogTitle className="text-2xl font-bold text-purple-800 flex items-center justify-between">
          <span>云养 {rabbitName}</span>
          <button
            onClick={() => {
              setStep('input');
              onClose();
            }}
            className="p-1 hover:bg-gray-100 rounded"
          >
            <X size={20} />
          </button>
        </DialogTitle>
        <DialogDescription className="text-sm text-gray-600">
          您的每笔贡献都将用于{rabbitName}的生活用品、粮草、药物等，每月金额的10%将转为云养币。
        </DialogDescription>

        <div className="mt-4 space-y-4">
          {/* 兔兔信息 */}
          <div className="flex gap-4 items-center bg-purple-50 rounded-xl p-3">
            <div className="w-16 h-16 rounded-lg overflow-hidden shadow flex-shrink-0">
              <img src={rabbitImage} alt={rabbitName} className="w-full h-full object-cover" />
            </div>
            <div>
              <p className="font-semibold text-gray-800">{rabbitName}</p>
              <p className="text-xs text-gray-500">云养贡献将用于兔兔日常养护</p>
            </div>
          </div>

          {step === 'input' ? (
            <form onSubmit={handleNextStep} className="space-y-4">
              {/* 金额输入 */}
              <div>
                <Label htmlFor="amount" className="text-sm font-medium">
                  云养金额（元）
                </Label>
                <div className="relative mt-1">
                  <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500">¥</span>
                  <Input
                    id="amount"
                    type="number"
                    min="1"
                    step="0.01"
                    value={amount}
                    onChange={(e) => setAmount(e.target.value)}
                    placeholder="请输入金额"
                    className="pl-8"
                    required
                  />
                </div>
              </div>

              {/* 快速选择 */}
              <div>
                <p className="text-sm font-medium text-gray-700 mb-2">快速选择</p>
                <div className="grid grid-cols-4 gap-2">
                  {quickAmounts.map((amt) => (
                    <button
                      key={amt}
                      type="button"
                      onClick={() => setAmount(amt.toString())}
                      className={`px-3 py-2 text-sm rounded-lg border transition-colors ${
                        amount === amt.toString()
                          ? 'border-purple-400 bg-purple-100 text-purple-700'
                          : 'border-purple-200 hover:bg-purple-50'
                      }`}
                    >
                      ¥{amt}
                    </button>
                  ))}
                </div>
              </div>

              {/* 云养币预览 */}
              {amount && parseFloat(amount) > 0 && (
                <div className="bg-purple-50 rounded-lg p-3 border border-purple-200">
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-gray-600">云养成功后您将获得</span>
                    <div className="flex items-center gap-1 text-purple-600 font-semibold">
                      <Coins size={16} />
                      {cloudCoins} 云养币
                    </div>
                  </div>
                </div>
              )}

              <Button
                type="submit"
                className="w-full bg-gradient-to-r from-purple-500 to-pink-500 hover:from-purple-600 hover:to-pink-600"
              >
                下一步：扫码支付
              </Button>
            </form>
          ) : (
            <div className="space-y-4">
              {/* 支付方式选择 */}
              <div>
                <p className="text-sm font-medium text-gray-700 mb-3">选择支付方式</p>
                <div className="grid grid-cols-2 gap-3">
                  <button
                    onClick={() => setPaymentMethod('wechat')}
                    className={`p-4 rounded-xl border-2 transition-all flex flex-col items-center gap-2 ${
                      paymentMethod === 'wechat'
                        ? 'border-green-500 bg-green-50'
                        : 'border-gray-200 hover:border-green-200'
                    }`}
                  >
                    <div className="w-10 h-10 bg-green-500 rounded-lg flex items-center justify-center">
                      <svg viewBox="0 0 24 24" className="w-6 h-6 text-white" fill="currentColor">
                        <path d="M8.691 2.188C3.891 2.188 0 5.476 0 9.53c0 2.212 1.17 4.203 3.002 5.55a.59.59 0 0 1 .213.665l-.39 1.48c-.019.07-.048.141-.048.213 0 .163.13.295.29.295a.326.326 0 0 0 .167-.054l1.903-1.114a.864.864 0 0 1 .717-.098 10.16 10.16 0 0 0 2.837.403c.276 0 .543-.027.811-.05-.857-2.578.157-4.972 1.932-6.446 1.703-1.415 3.882-1.98 5.853-1.838-.576-3.583-4.196-6.348-8.596-6.348zM5.785 5.991c.642 0 1.162.529 1.162 1.18a1.17 1.17 0 0 1-1.162 1.178A1.17 1.17 0 0 1 4.623 7.17c0-.651.52-1.18 1.162-1.18zm5.813 0c.642 0 1.162.529 1.162 1.18a1.17 1.17 0 0 1-1.162 1.178 1.17 1.17 0 0 1-1.162-1.178c0-.651.52-1.18 1.162-1.18zm5.34 2.867c-1.797-.052-3.746.512-5.28 1.786-1.72 1.428-2.687 3.72-1.78 6.22.942 2.453 3.666 4.229 6.884 4.229.826 0 1.622-.12 2.361-.336a.722.722 0 0 1 .598.082l1.584.926a.272.272 0 0 0 .14.047c.134 0 .24-.111.24-.247 0-.06-.023-.12-.038-.177l-.327-1.233a.582.582 0 0 1-.023-.156.49.49 0 0 1 .201-.398C23.024 18.48 24 16.82 24 14.98c0-3.21-2.931-5.837-6.656-6.088V8.89c-.135-.01-.269-.03-.406-.03zm-1.984 2.133c.535 0 .969.44.969.982a.976.976 0 0 1-.969.983.976.976 0 0 1-.969-.983c0-.542.434-.982.97-.982zm4.842 0c.535 0 .969.44.969.982a.976.976 0 0 1-.969.983.976.976 0 0 1-.969-.983c0-.542.434-.982.969-.982z"/>
                      </svg>
                    </div>
                    <span className="font-medium text-sm">微信支付</span>
                  </button>

                  <button
                    onClick={() => setPaymentMethod('alipay')}
                    className={`p-4 rounded-xl border-2 transition-all flex flex-col items-center gap-2 ${
                      paymentMethod === 'alipay'
                        ? 'border-blue-500 bg-blue-50'
                        : 'border-gray-200 hover:border-blue-200'
                    }`}
                  >
                    <div className="w-10 h-10 bg-blue-500 rounded-lg flex items-center justify-center">
                      <svg viewBox="0 0 24 24" className="w-6 h-6 text-white" fill="currentColor">
                        <path d="M21.88 8.05c.24-.8.2-1.47.2-2.38 0-1.32-1.1-2.67-3.08-2.67-1.95 0-4.03.95-5.63 2.45C11.76 4.1 10.06 3.05 8.1 3.05c-1.98 0-3.08 1.35-3.08 2.67 0 .91-.03 1.58.22 2.38-1.34.64-2.2 1.85-2.2 3.32 0 1.97 1.97 3.28 5.2 3.28 1.28 0 2.5-.3 3.6-.88v.04c0 .1 0 .2.05.3.1.2.18.43.28.63.3.6.6 1.2.95 1.75.7 1.1 1.5 2.15 2.45 2.95 1.9 1.6 4.15 2.4 6.6 2.4 2.95 0 5.35-1.25 6.85-3.7.95-1.55 1.3-3.35 1.3-5.6 0-2.5-1.05-4.75-2.85-6.3z"/>
                      </svg>
                    </div>
                    <span className="font-medium text-sm">支付宝</span>
                  </button>
                </div>
              </div>

              {/* 二维码 */}
              <div className="bg-gray-50 rounded-xl p-6 text-center">
                {hasQRCode ? (
                  <div className="rounded-xl overflow-hidden bg-white mx-auto mb-4" style={{ maxWidth: '200px' }}>
                    <img
                      src={currentQRCode!}
                      alt={`${paymentMethod === 'wechat' ? '微信' : '支付宝'}收款码`}
                      className="w-full object-contain"
                    />
                  </div>
                ) : (
                  <div className="w-48 h-48 bg-white rounded-xl mx-auto flex items-center justify-center border-2 border-dashed border-gray-300 mb-4">
                    <div className="text-center">
                      <div className="text-5xl mb-2">📱</div>
                      <p className="text-xs text-gray-400">暂未配置收款码</p>
                    </div>
                  </div>
                )}
                <p className="text-sm text-gray-600 mb-1">
                  支付金额：<span className="font-bold text-purple-600 text-lg">¥{amount}</span>
                </p>
                {hasQRCode ? (
                  <p className="text-xs text-gray-500">
                    请使用{paymentMethod === 'wechat' ? '微信' : '支付宝'}扫码支付
                  </p>
                ) : (
                  <p className="text-xs text-orange-500">管理员暂未配置收款码，请稍后再试</p>
                )}
              </div>

              {/* 提示 */}
              <div className="bg-orange-50 rounded-lg p-4 border border-orange-200">
                <h4 className="font-semibold text-gray-800 mb-2 flex items-center gap-2">
                  <span className="text-orange-500">⚠️</span> 重要提示
                </h4>
                <ul className="text-sm text-gray-600 space-y-1">
                  <li>• 支付完成后，点击「确认下单」</li>
                  <li>• 前往「我的订单」上传支付凭证截图</li>
                  <li>• 管理员审核通过后云养生效，获得{cloudCoins}云养币</li>
                </ul>
              </div>

              {/* 按钮 */}
              <div className="flex gap-3">
                <Button
                  type="button"
                  variant="outline"
                  onClick={() => setStep('input')}
                  className="flex-1"
                >
                  返回修改
                </Button>
                <Button
                  onClick={handleConfirm}
                  className="flex-1 bg-gradient-to-r from-purple-500 to-pink-500 hover:from-purple-600 hover:to-pink-600"
                >
                  <ShoppingBag size={16} className="mr-1" />
                  确认下单
                </Button>
              </div>
            </div>
          )}
        </div>
      </DialogContent>
    </Dialog>
  );
}
