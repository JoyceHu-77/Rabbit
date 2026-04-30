import { useState } from 'react';
import { Dialog, DialogContent, DialogTitle, DialogDescription } from '../ui/dialog';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Textarea } from '../ui/textarea';
import { Label } from '../ui/label';
import { toast } from 'sonner';
import { X } from 'lucide-react';

interface AdoptionFormProps {
  open: boolean;
  onClose: () => void;
  rabbitName: string;
  rabbitId: string;
}

export default function AdoptionForm({ open, onClose, rabbitName, rabbitId }: AdoptionFormProps) {
  const [formData, setFormData] = useState({
    name: '',
    phone: '',
    wechat: '',
    address: '',
    experience: '',
    environment: '',
    timeCommitment: '',
    reason: '',
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    // 验证必填项
    if (!formData.name || !formData.phone || !formData.address) {
      toast.error('请填写必填项', {
        description: '姓名、联系电话和居住地址为必填项',
      });
      return;
    }

    // 提交领养申请
    toast.success('领养申请已提交', {
      description: `您对${rabbitName}的领养申请已提交，管理员将尽快审核并与您联系。感谢您的爱心！`,
    });

    // 重置表单
    setFormData({
      name: '',
      phone: '',
      wechat: '',
      address: '',
      experience: '',
      environment: '',
      timeCommitment: '',
      reason: '',
    });

    onClose();
  };

  const handleChange = (field: string, value: string) => {
    setFormData(prev => ({ ...prev, [field]: value }));
  };

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto" showClose={false}>
        <DialogTitle className="text-2xl font-bold text-purple-800 flex items-center justify-between">
          <span>领养申请 - {rabbitName}</span>
          <button onClick={onClose} className="p-1 hover:bg-gray-100 rounded">
            <X size={20} />
          </button>
        </DialogTitle>
        <DialogDescription className="text-sm text-gray-600">
          请认真填写以下信息，我们会仔细审核每一份申请，确保每只兔兔都能找到合适的家庭。
        </DialogDescription>

        <form onSubmit={handleSubmit} className="space-y-6 mt-4">
          {/* 基本信息 */}
          <div className="space-y-4">
            <h3 className="font-semibold text-gray-800 border-b pb-2">基本信息</h3>

            <div>
              <Label htmlFor="name" className="text-sm font-medium">
                姓名 <span className="text-red-500">*</span>
              </Label>
              <Input
                id="name"
                value={formData.name}
                onChange={(e) => handleChange('name', e.target.value)}
                placeholder="请输入您的姓名"
                className="mt-1"
                required
              />
            </div>

            <div>
              <Label htmlFor="phone" className="text-sm font-medium">
                联系电话 <span className="text-red-500">*</span>
              </Label>
              <Input
                id="phone"
                type="tel"
                value={formData.phone}
                onChange={(e) => handleChange('phone', e.target.value)}
                placeholder="请输入您的联系电话"
                className="mt-1"
                required
              />
            </div>

            <div>
              <Label htmlFor="wechat" className="text-sm font-medium">
                微信号
              </Label>
              <Input
                id="wechat"
                value={formData.wechat}
                onChange={(e) => handleChange('wechat', e.target.value)}
                placeholder="请输入您的微信号（选填）"
                className="mt-1"
              />
            </div>

            <div>
              <Label htmlFor="address" className="text-sm font-medium">
                居住地址 <span className="text-red-500">*</span>
              </Label>
              <Input
                id="address"
                value={formData.address}
                onChange={(e) => handleChange('address', e.target.value)}
                placeholder="请输入您的详细地址"
                className="mt-1"
                required
              />
            </div>
          </div>

          {/* 养兔经验 */}
          <div className="space-y-4">
            <h3 className="font-semibold text-gray-800 border-b pb-2">养兔情况</h3>

            <div>
              <Label htmlFor="experience" className="text-sm font-medium">
                养兔经验
              </Label>
              <Textarea
                id="experience"
                value={formData.experience}
                onChange={(e) => handleChange('experience', e.target.value)}
                placeholder="请描述您的养兔经验（如有）"
                className="mt-1"
                rows={3}
              />
            </div>

            <div>
              <Label htmlFor="environment" className="text-sm font-medium">
                居住环境
              </Label>
              <Textarea
                id="environment"
                value={formData.environment}
                onChange={(e) => handleChange('environment', e.target.value)}
                placeholder="请描述您的居住环境，如房屋类型、是否有独立空间等"
                className="mt-1"
                rows={3}
              />
            </div>

            <div>
              <Label htmlFor="timeCommitment" className="text-sm font-medium">
                时间投入
              </Label>
              <Textarea
                id="timeCommitment"
                value={formData.timeCommitment}
                onChange={(e) => handleChange('timeCommitment', e.target.value)}
                placeholder="请说明您每天能投入多少时间照顾兔兔"
                className="mt-1"
                rows={2}
              />
            </div>

            <div>
              <Label htmlFor="reason" className="text-sm font-medium">
                领养原因
              </Label>
              <Textarea
                id="reason"
                value={formData.reason}
                onChange={(e) => handleChange('reason', e.target.value)}
                placeholder="请告诉我们您为什么想领养这只兔兔"
                className="mt-1"
                rows={3}
              />
            </div>
          </div>

          {/* 承诺声明 */}
          <div className="bg-purple-50 rounded-lg p-4 border border-purple-200">
            <h3 className="font-semibold text-gray-800 mb-2">领养承诺</h3>
            <ul className="text-sm text-gray-600 space-y-1">
              <li>• 我承诺为兔兔提供安全、舒适的生活环境</li>
              <li>• 我承诺按时提供充足的食物和清洁的饮水</li>
              <li>• 我承诺在兔兔生病时及时就医</li>
              <li>• 我承诺接受爱兔会的定期回访</li>
              <li>• 我承诺不以任何理由遗弃或虐待兔兔</li>
            </ul>
          </div>

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
              type="submit"
              className="flex-1 bg-gradient-to-r from-red-500 to-rose-500 hover:from-purple-600 hover:to-pink-600"
            >
              提交申请
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}
