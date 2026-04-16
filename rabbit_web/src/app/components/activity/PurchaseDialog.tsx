import { useState } from 'react';
import { Dialog, DialogContent, DialogTitle, DialogDescription } from '../ui/dialog';
import { Button } from '../ui/button';
import { toast } from 'sonner';
import { X, CreditCard, Award, Coins } from 'lucide-react';

interface PurchaseDialogProps {
  open: boolean;
  onClose: () => void;
  product: {
    name: string;
    image: string;
    price: number;
    badges: number;
    cloudCoins: number;
  } | null;
  mode: 'purchase' | 'badge' | 'coin';
}

export default function PurchaseDialog({ open, onClose, product, mode }: PurchaseDialogProps) {
  const [paymentMethod, setPaymentMethod] = useState<'wechat' | 'alipay'>('wechat');

  if (!product) return null;

  const handleConfirm = () => {
    if (mode === 'purchase') {
      toast.success('支付成功！', {
        description: '商品将自动发货至您的个人页，请注意查收',
      });
    } else if (mode === 'badge') {
      toast.success('兑换成功！', {
        description: `已使用${product.badges}枚爱兔奖章兑换成功`,
      });
    } else {
      toast.success('兑换成功！', {
        description: `已使用${product.cloudCoins}个云养币兑换成功`,
      });
    }
    onClose();
  };

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-md" showClose={false}>
        <DialogTitle className="text-2xl font-bold text-pink-800 flex items-center justify-between">
          <span>
            {mode === 'purchase' ? '购买' : '兑换'}商品
          </span>
          <button onClick={onClose} className="p-1 hover:bg-gray-100 rounded">
            <X size={20} />
          </button>
        </DialogTitle>
        <DialogDescription className="text-sm text-gray-600">
          {mode === 'purchase'
            ? '请选择支付方式完成购买'
            : '确认使用积分兑换该商品'}
        </DialogDescription>

        <div className="mt-4 space-y-4">
          {/* 商品信息 */}
          <div className="flex gap-4 items-center bg-gray-50 rounded-lg p-4">
            <div className="w-20 h-20 rounded-lg overflow-hidden flex-shrink-0">
              <img
                src={product.image}
                alt={product.name}
                className="w-full h-full object-cover"
              />
            </div>
            <div className="flex-1">
              <h3 className="font-semibold text-gray-800 mb-1">{product.name}</h3>
              {mode === 'purchase' && (
                <p className="text-lg font-bold text-pink-600">¥{product.price}</p>
              )}
              {mode === 'badge' && (
                <div className="flex items-center gap-1 text-pink-600 font-semibold">
                  <Award size={16} />
                  {product.badges} 枚奖章
                </div>
              )}
              {mode === 'coin' && (
                <div className="flex items-center gap-1 text-purple-600 font-semibold">
                  <Coins size={16} />
                  {product.cloudCoins} 云养币
                </div>
              )}
            </div>
          </div>

          {/* 支付方式（仅购买模式） */}
          {mode === 'purchase' && (
            <div>
              <p className="text-sm font-medium text-gray-700 mb-3">支付方式</p>
              <div className="space-y-2">
                <label
                  className={`flex items-center gap-3 p-3 rounded-lg border-2 cursor-pointer transition-colors ${
                    paymentMethod === 'wechat'
                      ? 'border-green-500 bg-green-50'
                      : 'border-gray-200 hover:bg-gray-50'
                  }`}
                >
                  <input
                    type="radio"
                    checked={paymentMethod === 'wechat'}
                    onChange={() => setPaymentMethod('wechat')}
                    className="w-4 h-4"
                  />
                  <div className="flex-1 flex items-center gap-2">
                    <div className="w-8 h-8 bg-green-500 rounded flex items-center justify-center text-white text-xs font-bold">
                      微
                    </div>
                    <span className="font-medium">微信支付</span>
                  </div>
                </label>

                <label
                  className={`flex items-center gap-3 p-3 rounded-lg border-2 cursor-pointer transition-colors ${
                    paymentMethod === 'alipay'
                      ? 'border-blue-500 bg-blue-50'
                      : 'border-gray-200 hover:bg-gray-50'
                  }`}
                >
                  <input
                    type="radio"
                    checked={paymentMethod === 'alipay'}
                    onChange={() => setPaymentMethod('alipay')}
                    className="w-4 h-4"
                  />
                  <div className="flex-1 flex items-center gap-2">
                    <div className="w-8 h-8 bg-blue-500 rounded flex items-center justify-center text-white text-xs font-bold">
                      支
                    </div>
                    <span className="font-medium">支付宝</span>
                  </div>
                </label>
              </div>
            </div>
          )}

          {/* 提示信息 */}
          <div className="bg-orange-50 rounded-lg p-3 border border-orange-200">
            <p className="text-sm text-gray-600">
              {mode === 'purchase'
                ? '购买后商品将自动发货至您的个人页消息中心'
                : '兑换后商品将发送至您的个人页消息中心'}
            </p>
          </div>

          {/* 按钮 */}
          <div className="flex gap-3">
            <Button
              type="button"
              variant="outline"
              onClick={onClose}
              className="flex-1"
            >
              取消
            </Button>
            <Button
              onClick={handleConfirm}
              className="flex-1 bg-gradient-to-r from-pink-500 to-orange-500 hover:from-pink-600 hover:to-orange-600"
            >
              {mode === 'purchase' ? (
                <>
                  <CreditCard size={16} className="mr-1" />
                  确认支付
                </>
              ) : (
                <>
                  {mode === 'badge' ? <Award size={16} className="mr-1" /> : <Coins size={16} className="mr-1" />}
                  确认兑换
                </>
              )}
            </Button>
          </div>

          {mode === 'purchase' && (
            <p className="text-xs text-gray-500 text-center">
              提示：实际应用中将调用第三方支付接口
            </p>
          )}
        </div>
      </DialogContent>
    </Dialog>
  );
}
