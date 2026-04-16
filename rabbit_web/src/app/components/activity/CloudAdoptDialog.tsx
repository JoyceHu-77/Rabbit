import { useState } from 'react';
import { Dialog, DialogContent, DialogTitle, DialogDescription } from '../ui/dialog';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { toast } from 'sonner';
import { X, Coins } from 'lucide-react';

interface CloudAdoptDialogProps {
  open: boolean;
  onClose: () => void;
  rabbitName: string;
  rabbitImage: string;
}

export default function CloudAdoptDialog({
  open,
  onClose,
  rabbitName,
  rabbitImage,
}: CloudAdoptDialogProps) {
  const [amount, setAmount] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    const numAmount = parseFloat(amount);
    if (!numAmount || numAmount < 1) {
      toast.error('请输入有效金额', {
        description: '云养金额需大于等于1元',
      });
      return;
    }

    const cloudCoins = Math.floor(numAmount * 0.1);

    toast.success('云养成功！', {
      description: `您已为${rabbitName}云养¥${numAmount}，获得${cloudCoins}个云养币`,
    });

    setAmount('');
    onClose();
  };

  const quickAmounts = [10, 30, 50, 100];

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-md" showClose={false}>
        <DialogTitle className="text-2xl font-bold text-purple-800 flex items-center justify-between">
          <span>云养 {rabbitName}</span>
          <button onClick={onClose} className="p-1 hover:bg-gray-100 rounded">
            <X size={20} />
          </button>
        </DialogTitle>
        <DialogDescription className="text-sm text-gray-600">
          您的每笔贡献都将用于{rabbitName}的生活用品、粮草、药物等，每月金额的10%将转为云养币。
        </DialogDescription>

        <div className="mt-4">
          <div className="aspect-square w-32 h-32 mx-auto rounded-xl overflow-hidden shadow-md mb-4">
            <img
              src={rabbitImage}
              alt={rabbitName}
              className="w-full h-full object-cover"
            />
          </div>

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <Label htmlFor="amount" className="text-sm font-medium">
                云养金额（元）
              </Label>
              <div className="relative mt-1">
                <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500">
                  ¥
                </span>
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

            <div>
              <p className="text-sm font-medium text-gray-700 mb-2">快速选择</p>
              <div className="grid grid-cols-4 gap-2">
                {quickAmounts.map((amt) => (
                  <button
                    key={amt}
                    type="button"
                    onClick={() => setAmount(amt.toString())}
                    className="px-3 py-2 text-sm rounded-lg border border-purple-200 hover:bg-purple-50 transition-colors"
                  >
                    ¥{amt}
                  </button>
                ))}
              </div>
            </div>

            {amount && parseFloat(amount) > 0 && (
              <div className="bg-purple-50 rounded-lg p-3 border border-purple-200">
                <div className="flex items-center justify-between text-sm">
                  <span className="text-gray-600">您将获得</span>
                  <div className="flex items-center gap-1 text-purple-600 font-semibold">
                    <Coins size={16} />
                    {Math.floor(parseFloat(amount) * 0.1)} 云养币
                  </div>
                </div>
              </div>
            )}

            <div className="flex gap-3 pt-2">
              <Button
                type="button"
                variant="outline"
                onClick={onClose}
                className="flex-1"
              >
                取消
              </Button>
              <Button
                type="submit"
                className="flex-1 bg-gradient-to-r from-purple-500 to-pink-500 hover:from-purple-600 hover:to-pink-600"
              >
                确认云养
              </Button>
            </div>
          </form>

          <p className="text-xs text-gray-500 text-center mt-4">
            提示：实际应用中将调用支付接口完成支付
          </p>
        </div>
      </DialogContent>
    </Dialog>
  );
}
