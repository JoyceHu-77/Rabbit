import { useState } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '../ui/dialog';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Textarea } from '../ui/textarea';
import { Upload } from 'lucide-react';
import { toast } from 'sonner';

interface CreateDonationPostProps {
  open: boolean;
  onClose: () => void;
  onSubmit: (post: any) => void;
}

export default function CreateDonationPost({
  open,
  onClose,
  onSubmit,
}: CreateDonationPostProps) {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [type, setType] = useState<'捐赠' | '置换'>('捐赠');
  const [target, setTarget] = useState<'爱兔会' | '共享'>('共享');
  const [contactName, setContactName] = useState('');
  const [contactPhone, setContactPhone] = useState('');

  const handleSubmit = () => {
    if (!title || !description || !contactName || !contactPhone) {
      toast.error('请填写所有必填项');
      return;
    }

    const newPost = {
      title,
      description,
      image: 'https://images.unsplash.com/photo-1578164252938-1da0cd4caa30?w=400',
      type,
      target,
      status: '待领取' as const,
      contact: { name: contactName, phone: contactPhone },
    };

    onSubmit(newPost);
    toast.success('发布成功！');

    setTitle('');
    setDescription('');
    setType('捐赠');
    setTarget('共享');
    setContactName('');
    setContactPhone('');
  };

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-lg max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="text-2xl text-orange-800">发布捐赠/置换</DialogTitle>
          <DialogDescription className="text-sm text-gray-600">
            分享您的爱心物资，帮助更多需要的兔兔
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4 py-4">
          <div>
            <label className="text-sm font-medium text-gray-700 mb-2 block">
              上传图片 <span className="text-red-500">*</span>
            </label>
            <div className="border-2 border-dashed border-orange-200 rounded-lg p-8 text-center hover:border-orange-400 transition-colors cursor-pointer">
              <Upload size={32} className="mx-auto text-orange-400 mb-2" />
              <p className="text-sm text-gray-600">点击上传物品图片</p>
            </div>
          </div>

          <div>
            <label className="text-sm font-medium text-gray-700 mb-2 block">
              物品名称 <span className="text-red-500">*</span>
            </label>
            <Input
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="例如：兔粮500g × 3包"
            />
          </div>

          <div>
            <label className="text-sm font-medium text-gray-700 mb-2 block">
              物品描述 <span className="text-red-500">*</span>
            </label>
            <Textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="详细描述物品状况、数量等信息"
              rows={3}
            />
          </div>

          <div>
            <label className="text-sm font-medium text-gray-700 mb-2 block">
              类型 <span className="text-red-500">*</span>
            </label>
            <div className="flex gap-4">
              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="radio"
                  checked={type === '捐赠'}
                  onChange={() => setType('捐赠')}
                  className="w-4 h-4 text-green-500"
                />
                <span className="text-gray-700">捐赠</span>
              </label>
              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="radio"
                  checked={type === '置换'}
                  onChange={() => setType('置换')}
                  className="w-4 h-4 text-blue-500"
                />
                <span className="text-gray-700">置换</span>
              </label>
            </div>
          </div>

          {type === '捐赠' && (
            <div>
              <label className="text-sm font-medium text-gray-700 mb-2 block">
                捐赠对象 <span className="text-red-500">*</span>
              </label>
              <div className="flex gap-4">
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="radio"
                    checked={target === '共享'}
                    onChange={() => setTarget('共享')}
                    className="w-4 h-4 text-orange-500"
                  />
                  <span className="text-gray-700">共享（所有用户可领取）</span>
                </label>
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="radio"
                    checked={target === '爱兔会'}
                    onChange={() => setTarget('爱兔会')}
                    className="w-4 h-4 text-orange-500"
                  />
                  <span className="text-gray-700">指定爱兔会</span>
                </label>
              </div>
            </div>
          )}

          <div className="border-t pt-4">
            <h3 className="font-medium text-gray-800 mb-3">联系方式</h3>

            <div className="space-y-3">
              <Input
                value={contactName}
                onChange={(e) => setContactName(e.target.value)}
                placeholder="您的称呼"
              />

              <Input
                value={contactPhone}
                onChange={(e) => setContactPhone(e.target.value)}
                placeholder="联系方式（手机号/微信）"
              />
            </div>
          </div>
        </div>

        <div className="flex gap-3 pt-4">
          <Button variant="outline" onClick={onClose} className="flex-1">
            取消
          </Button>
          <Button
            onClick={handleSubmit}
            className="flex-1 bg-gradient-to-r from-rose-600 to-red-600 hover:from-orange-600 hover:to-pink-600"
          >
            发布
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}
