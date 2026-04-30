import { useState } from 'react';
import { Dialog, DialogContent, DialogTitle } from '../ui/dialog';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { X, MapPin, Plus, Check, Truck } from 'lucide-react';
import { toast } from 'sonner';
import badgeImg from '../../../imports/爱兔会徽章1.jpeg';

interface Address {
  id: string;
  name: string;
  phone: string;
  province: string;
  city: string;
  district: string;
  detail: string;
  isDefault: boolean;
}

interface BadgeDeliveryDialogProps {
  open: boolean;
  onClose: () => void;
  mode: 'online' | 'offline';
  userId: string;
  userName: string;
  cloudRabbits: { name: string; image: string; date: string }[];
}

export default function BadgeDeliveryDialog({
  open,
  onClose,
  mode,
  userId,
  userName,
  cloudRabbits,
}: BadgeDeliveryDialogProps) {
  const [addresses, setAddresses] = useState<Address[]>([
    {
      id: '1',
      name: '张女士',
      phone: '138****1234',
      province: '上海市',
      city: '上海市',
      district: '黄浦区',
      detail: '南京东路123号',
      isDefault: true,
    },
  ]);
  const [showAddForm, setShowAddForm] = useState(false);
  const [selectedAddressId, setSelectedAddressId] = useState<string>('1');
  const [formData, setFormData] = useState({
    name: '',
    phone: '',
    province: '上海市',
    city: '上海市',
    district: '',
    detail: '',
  });

  const selectedAddress = addresses.find(a => a.id === selectedAddressId);

  const handleAddAddress = () => {
    if (!formData.name || !formData.phone || !formData.district || !formData.detail) {
      toast.error('请填写完整地址信息');
      return;
    }
    const newAddress: Address = {
      id: Date.now().toString(),
      ...formData,
      isDefault: false,
    };
    setAddresses([...addresses, newAddress]);
    setSelectedAddressId(newAddress.id);
    setFormData({ name: '', phone: '', province: '上海市', city: '上海市', district: '', detail: '' });
    setShowAddForm(false);
    toast.success('地址添加成功');
  };

  const handleConfirmOnline = () => {
    if (!selectedAddress) {
      toast.error('请选择收货地址');
      return;
    }
    toast.success('已提交线上发货申请', {
      description: '工作人员将尽快与您联系发货',
    });
    onClose();
  };

  if (mode === 'offline') {
    const today = new Date().toISOString().split('T')[0];
    const rabbitNames = cloudRabbits.map(r => r.name).join('、') || '爱心云养';

    return (
      <Dialog open={open} onOpenChange={onClose}>
        <DialogContent className="max-w-md" showClose={false}>
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-xl font-bold text-purple-800 flex items-center gap-2">
              <Truck size={24} className="text-pink-600" />
              线下领取凭证
            </h2>
            <button onClick={onClose} className="p-1 hover:bg-gray-100 rounded">
              <X size={20} />
            </button>
          </div>

          <p className="text-sm text-gray-600 mb-4">
            请保存下方凭证，下次参与爱兔会活动时出示给工作人员查看，即可领取志愿者徽章。
          </p>

          {/* 海报区域 */}
          <div className="bg-gradient-to-br from-purple-100 via-pink-50 to-purple-50 rounded-2xl p-6 border-2 border-pink-200">
            <div className="text-center mb-4">
              <div className="w-20 h-20 mx-auto mb-3 rounded-xl overflow-hidden shadow-lg">
                <img src={badgeImg} alt="志愿者徽章" className="w-full h-full object-contain bg-white" />
              </div>
              <h3 className="text-lg font-bold text-purple-800">爱兔会志愿者徽章领取凭证</h3>
              <p className="text-xs text-gray-500 mt-1">仅限本人使用，不可转让</p>
            </div>

            <div className="space-y-2 text-sm">
              <div className="flex justify-between items-center py-2 border-b border-purple-100">
                <span className="text-gray-500">用户ID</span>
                <span className="font-semibold text-gray-800">{userId}</span>
              </div>
              <div className="flex justify-between items-center py-2 border-b border-purple-100">
                <span className="text-gray-500">用户昵称</span>
                <span className="font-semibold text-gray-800">{userName}</span>
              </div>
              <div className="flex justify-between items-center py-2 border-b border-purple-100">
                <span className="text-gray-500">云养兔兔</span>
                <span className="font-semibold text-gray-800 text-right max-w-[180px]">{rabbitNames}</span>
              </div>
              <div className="flex justify-between items-center py-2">
                <span className="text-gray-500">领取日期</span>
                <span className="font-semibold text-gray-800">{today}</span>
              </div>
            </div>

            <div className="mt-4 pt-4 border-t border-purple-200 text-center">
              <p className="text-xs text-gray-500">
                出示本凭证至爱兔会基地<br />即可领取志愿者徽章一枚
              </p>
            </div>
          </div>

          <Button
            onClick={onClose}
            className="w-full mt-4 bg-gradient-to-r from-purple-500 to-pink-500 hover:from-purple-600 hover:to-pink-600"
          >
            我知道了
          </Button>
        </DialogContent>
      </Dialog>
    );
  }

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-lg max-h-[80vh] overflow-y-auto" showClose={false}>
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-xl font-bold text-purple-800 flex items-center gap-2">
            <Truck size={24} className="text-pink-600" />
            线上发货
          </h2>
          <button onClick={onClose} className="p-1 hover:bg-gray-100 rounded">
            <X size={20} />
          </button>
        </div>

        <p className="text-sm text-gray-600 mb-4">
          请选择收货地址，志愿者徽章将通过快递寄送给您。
        </p>

        {/* 徽章预览 */}
        <div className="flex items-center gap-3 p-3 bg-purple-50 rounded-xl mb-4">
          <div className="w-16 h-16 rounded-lg overflow-hidden shadow">
            <img src={badgeImg} alt="志愿者徽章" className="w-full h-full object-contain bg-white" />
          </div>
          <div>
            <p className="font-semibold text-gray-800">爱兔会志愿者徽章</p>
            <p className="text-xs text-gray-500">云养活动专属纪念品</p>
          </div>
        </div>

        {/* 地址列表 */}
        <div className="space-y-3 mb-4">
          <Label className="text-sm font-medium">选择收货地址</Label>
          {addresses.length === 0 ? (
            <p className="text-sm text-gray-500 text-center py-4">暂无收货地址，请新增</p>
          ) : (
            addresses.map((address) => (
              <button
                key={address.id}
                onClick={() => setSelectedAddressId(address.id)}
                className={`w-full p-4 rounded-xl border text-left transition-all ${
                  selectedAddressId === address.id
                    ? 'border-purple-400 bg-purple-50'
                    : 'border-gray-200 bg-white hover:border-purple-300'
                }`}
              >
                <div className="flex items-start gap-3">
                  <div className={`w-5 h-5 rounded-full border-2 flex items-center justify-center flex-shrink-0 mt-0.5 ${
                    selectedAddressId === address.id ? 'border-purple-500 bg-purple-500' : 'border-gray-300'
                  }`}>
                    {selectedAddressId === address.id && (
                      <Check size={12} className="text-white" />
                    )}
                  </div>
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-1">
                      <span className="font-semibold text-gray-800">{address.name}</span>
                      <span className="text-gray-600">{address.phone}</span>
                      {address.isDefault && (
                        <span className="px-2 py-0.5 bg-purple-100 text-purple-600 rounded text-xs">默认</span>
                      )}
                    </div>
                    <p className="text-sm text-gray-600">
                      {address.province} {address.city} {address.district} {address.detail}
                    </p>
                  </div>
                </div>
              </button>
            ))
          )}

          {/* 新增地址表单 */}
          {showAddForm ? (
            <div className="p-4 bg-gray-50 rounded-xl border border-gray-200">
              <h4 className="font-semibold text-gray-800 mb-3">新增地址</h4>
              <div className="space-y-3">
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <Label htmlFor="dlg-name" className="text-xs">收货人</Label>
                    <Input
                      id="dlg-name"
                      value={formData.name}
                      onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                      placeholder="请输入姓名"
                      className="mt-1"
                    />
                  </div>
                  <div>
                    <Label htmlFor="dlg-phone" className="text-xs">联系电话</Label>
                    <Input
                      id="dlg-phone"
                      type="tel"
                      value={formData.phone}
                      onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                      placeholder="请输入电话"
                      className="mt-1"
                    />
                  </div>
                </div>
                <div>
                  <Label htmlFor="dlg-district" className="text-xs">区县</Label>
                  <Input
                    id="dlg-district"
                    value={formData.district}
                    onChange={(e) => setFormData({ ...formData, district: e.target.value })}
                    placeholder="如：黄浦区"
                    className="mt-1"
                  />
                </div>
                <div>
                  <Label htmlFor="dlg-detail" className="text-xs">详细地址</Label>
                  <Input
                    id="dlg-detail"
                    value={formData.detail}
                    onChange={(e) => setFormData({ ...formData, detail: e.target.value })}
                    placeholder="请输入详细地址"
                    className="mt-1"
                  />
                </div>
                <div className="flex gap-2 pt-2">
                  <Button
                    type="button"
                    variant="outline"
                    onClick={() => setShowAddForm(false)}
                    className="flex-1"
                  >
                    取消
                  </Button>
                  <Button
                    onClick={handleAddAddress}
                    className="flex-1 bg-gradient-to-r from-purple-500 to-pink-500 hover:from-purple-600 hover:to-pink-600"
                  >
                    保存地址
                  </Button>
                </div>
              </div>
            </div>
          ) : (
            <Button
              onClick={() => setShowAddForm(true)}
              variant="outline"
              className="w-full border-purple-200 hover:bg-purple-50 text-purple-600"
            >
              <Plus size={16} className="mr-1" />
              新增收货地址
            </Button>
          )}
        </div>

        <Button
          onClick={handleConfirmOnline}
          disabled={!selectedAddress}
          className="w-full bg-gradient-to-r from-purple-500 to-pink-500 hover:from-purple-600 hover:to-pink-600 disabled:opacity-50"
        >
          确认发货
        </Button>
      </DialogContent>
    </Dialog>
  );
}
