import { useState } from 'react';
import { Dialog, DialogContent, DialogTitle, DialogDescription } from '../ui/dialog';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { toast } from 'sonner';
import { X, MapPin, Plus, Trash2, Edit } from 'lucide-react';

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

interface AddressDialogProps {
  open: boolean;
  onClose: () => void;
}

export default function AddressDialog({ open, onClose }: AddressDialogProps) {
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
  const [formData, setFormData] = useState({
    name: '',
    phone: '',
    province: '上海市',
    city: '上海市',
    district: '',
    detail: '',
  });

  const handleAddAddress = () => {
    if (!formData.name || !formData.phone || !formData.district || !formData.detail) {
      toast.error('请填写完整地址信息');
      return;
    }

    const newAddress: Address = {
      id: Date.now().toString(),
      ...formData,
      isDefault: addresses.length === 0,
    };

    setAddresses([...addresses, newAddress]);
    setFormData({
      name: '',
      phone: '',
      province: '上海市',
      city: '上海市',
      district: '',
      detail: '',
    });
    setShowAddForm(false);
    toast.success('地址添加成功');
  };

  const handleDeleteAddress = (id: string) => {
    setAddresses(addresses.filter(addr => addr.id !== id));
    toast.success('地址已删除');
  };

  const handleSetDefault = (id: string) => {
    setAddresses(addresses.map(addr => ({
      ...addr,
      isDefault: addr.id === id,
    })));
    toast.success('已设为默认地址');
  };

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-2xl max-h-[80vh] overflow-y-auto" showClose={false}>
        <DialogTitle className="text-2xl font-bold text-gray-800 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <MapPin size={24} className="text-red-600" />
            <span>收货地址</span>
          </div>
          <button onClick={onClose} className="p-1 hover:bg-gray-100 rounded">
            <X size={20} />
          </button>
        </DialogTitle>
        <DialogDescription className="text-sm text-gray-600">
          管理您的收货地址，用于实物发货
        </DialogDescription>

        <div className="space-y-3 mt-4">
          {/* 地址列表 */}
          {addresses.map((address) => (
            <div
              key={address.id}
              className={`p-4 rounded-xl border ${
                address.isDefault
                  ? 'bg-red-50 border-red-300'
                  : 'bg-white border-gray-200'
              }`}
            >
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-2">
                    <span className="font-semibold text-gray-800">{address.name}</span>
                    <span className="text-gray-600">{address.phone}</span>
                    {address.isDefault && (
                      <span className="px-2 py-0.5 bg-red-500 text-white rounded text-xs">
                        默认
                      </span>
                    )}
                  </div>
                  <p className="text-sm text-gray-600">
                    {address.province} {address.city} {address.district} {address.detail}
                  </p>
                </div>

                <div className="flex gap-2">
                  {!address.isDefault && (
                    <button
                      onClick={() => handleSetDefault(address.id)}
                      className="p-2 hover:bg-gray-100 rounded transition-colors"
                      title="设为默认"
                    >
                      <Edit size={16} className="text-gray-600" />
                    </button>
                  )}
                  <button
                    onClick={() => handleDeleteAddress(address.id)}
                    className="p-2 hover:bg-red-50 rounded transition-colors"
                    title="删除"
                  >
                    <Trash2 size={16} className="text-red-500" />
                  </button>
                </div>
              </div>
            </div>
          ))}

          {/* 添加地址表单 */}
          {showAddForm ? (
            <div className="p-4 bg-gray-50 rounded-xl border border-gray-200">
              <h3 className="font-semibold text-gray-800 mb-4">新增地址</h3>
              <div className="space-y-3">
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <Label htmlFor="name" className="text-sm">收货人</Label>
                    <Input
                      id="name"
                      value={formData.name}
                      onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                      placeholder="请输入收货人姓名"
                      className="mt-1"
                    />
                  </div>
                  <div>
                    <Label htmlFor="phone" className="text-sm">联系电话</Label>
                    <Input
                      id="phone"
                      type="tel"
                      value={formData.phone}
                      onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                      placeholder="请输入联系电话"
                      className="mt-1"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-3 gap-3">
                  <div>
                    <Label htmlFor="province" className="text-sm">省份</Label>
                    <Input
                      id="province"
                      value={formData.province}
                      disabled
                      className="mt-1 bg-gray-100"
                    />
                  </div>
                  <div>
                    <Label htmlFor="city" className="text-sm">城市</Label>
                    <Input
                      id="city"
                      value={formData.city}
                      disabled
                      className="mt-1 bg-gray-100"
                    />
                  </div>
                  <div>
                    <Label htmlFor="district" className="text-sm">区县</Label>
                    <Input
                      id="district"
                      value={formData.district}
                      onChange={(e) => setFormData({ ...formData, district: e.target.value })}
                      placeholder="如黄浦区"
                      className="mt-1"
                    />
                  </div>
                </div>

                <div>
                  <Label htmlFor="detail" className="text-sm">详细地址</Label>
                  <Input
                    id="detail"
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
                    onClick={() => {
                      setShowAddForm(false);
                      setFormData({
                        name: '',
                        phone: '',
                        province: '上海市',
                        city: '上海市',
                        district: '',
                        detail: '',
                      });
                    }}
                    className="flex-1"
                  >
                    取消
                  </Button>
                  <Button
                    onClick={handleAddAddress}
                    className="flex-1 bg-gradient-to-r from-pink-500 to-purple-500 hover:from-pink-600 hover:to-purple-600"
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
              className="w-full border-red-200 hover:bg-red-50 text-red-600"
            >
              <Plus size={16} className="mr-1" />
              新增地址
            </Button>
          )}
        </div>
      </DialogContent>
    </Dialog>
  );
}
