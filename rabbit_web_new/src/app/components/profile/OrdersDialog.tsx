import { useState, useRef, useEffect } from 'react';
import { Dialog, DialogContent, DialogTitle } from '../ui/dialog';
import { Button } from '../ui/button';
import { toast } from 'sonner';
import { X, ShoppingBag, Upload, CheckCircle, Clock, Image as ImageIcon, Coins } from 'lucide-react';
import { motion } from 'motion/react';
import { sendAdminNotification } from './MessagesDialog';

export interface Order {
  id: string;
  productName: string;
  productImage: string;
  price: number;
  status: 'pending' | 'paid' | 'shipped' | 'completed';
  createdAt: string;
  paidAt?: string;
  screenshot?: string;
  type?: 'product' | 'cloudAdopt';
  cloudCoins?: number;
}

export interface CloudAdoptOrder {
  id: string;
  rabbitName: string;
  rabbitImage: string;
  amount: number;
  cloudCoins: number;
  status: 'pending' | 'paid' | 'completed';
  createdAt: string;
  paidAt?: string;
  screenshot?: string;
}

const loadOrders = (): Order[] => {
  try {
    const saved = localStorage.getItem('userOrders');
    if (saved) return JSON.parse(saved);
  } catch (e) {
    console.error('Failed to load orders:', e);
  }
  return [];
};

const saveOrders = (orders: Order[]) => {
  try {
    localStorage.setItem('userOrders', JSON.stringify(orders));
  } catch (e) {
    console.error('Failed to save orders:', e);
  }
};

const loadCloudAdoptOrders = (): CloudAdoptOrder[] => {
  try {
    const saved = localStorage.getItem('cloudAdoptOrders');
    if (saved) return JSON.parse(saved);
  } catch (e) {
    console.error('Failed to load cloud adopt orders:', e);
  }
  return [];
};

const saveCloudAdoptOrders = (orders: CloudAdoptOrder[]) => {
  try {
    localStorage.setItem('cloudAdoptOrders', JSON.stringify(orders));
  } catch (e) {
    console.error('Failed to save cloud adopt orders:', e);
  }
};

export const addCloudAdoptOrder = (data: {
  rabbitName: string;
  rabbitImage: string;
  amount: number;
  cloudCoins: number;
}) => {
  const orders = loadCloudAdoptOrders();
  const newOrder: CloudAdoptOrder = {
    id: `CA${Date.now()}`,
    ...data,
    status: 'pending',
    createdAt: new Date().toISOString(),
  };
  orders.unshift(newOrder);
  saveCloudAdoptOrders(orders);
  return newOrder;
};

interface OrdersDialogProps {
  open: boolean;
  onClose: () => void;
  onCloudCoinsEarned?: (coins: number) => void;
}

export default function OrdersDialog({ open, onClose, onCloudCoinsEarned }: OrdersDialogProps) {
  const [orders, setOrders] = useState<Order[]>([]);
  const [cloudAdoptOrders, setCloudAdoptOrders] = useState<CloudAdoptOrder[]>([]);
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null);
  const [selectedCloudOrder, setSelectedCloudOrder] = useState<CloudAdoptOrder | null>(null);
  const [uploadingScreenshot, setUploadingScreenshot] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (open) {
      setOrders(loadOrders());
      setCloudAdoptOrders(loadCloudAdoptOrders());
    }
  }, [open]);

  const getStatusConfig = (status: Order['status']) => {
    switch (status) {
      case 'pending':
        return { label: '待上传凭证', color: 'bg-orange-100 text-orange-700', icon: Clock };
      case 'paid':
        return { label: '待发货', color: 'bg-blue-100 text-blue-700', icon: Clock };
      case 'shipped':
        return { label: '已发货', color: 'bg-purple-100 text-purple-700', icon: CheckCircle };
      case 'completed':
        return { label: '已完成', color: 'bg-green-100 text-green-700', icon: CheckCircle };
    }
  };

  const getCloudStatusConfig = (status: CloudAdoptOrder['status']) => {
    switch (status) {
      case 'pending':
        return { label: '待上传凭证', color: 'bg-orange-100 text-orange-700', icon: Clock };
      case 'paid':
        return { label: '待审核', color: 'bg-blue-100 text-blue-700', icon: Clock };
      case 'completed':
        return { label: '已完成', color: 'bg-green-100 text-green-700', icon: CheckCircle };
    }
  };

  const handleUploadScreenshot = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file || !selectedOrder) return;

    setUploadingScreenshot(true);
    const reader = new FileReader();
    reader.onloadend = () => {
      const updatedOrders = orders.map(order => {
        if (order.id === selectedOrder.id) {
          return {
            ...order,
            screenshot: reader.result as string,
            paidAt: new Date().toISOString(),
            status: 'paid' as const,
          };
        }
        return order;
      });
      setOrders(updatedOrders);
      saveOrders(updatedOrders);
      setSelectedOrder(prev => prev ? {
        ...prev,
        screenshot: reader.result as string,
        paidAt: new Date().toISOString(),
        status: 'paid' as const,
      } : null);
      setUploadingScreenshot(false);

      const orderData = updatedOrders.find(o => o.id === selectedOrder.id);
      console.log('[OrdersDialog] Sending notification for order:', orderData?.productName);
      if (orderData) {
        sendAdminNotification({
          type: 'payment',
          title: '新订单待发货',
          content: `用户购买了"${orderData.productName}"，已上传支付凭证，请及时处理发货`,
          orderId: selectedOrder.id,
          screenshot: reader.result as string,
        });
      }

      toast.success('凭证上传成功！', {
        description: '管理员审核后将会发货，请耐心等待',
      });
    };
    reader.readAsDataURL(file);
  };

  const handleUploadCloudScreenshot = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file || !selectedCloudOrder) return;

    setUploadingScreenshot(true);
    const reader = new FileReader();
    reader.onloadend = () => {
      const updated = cloudAdoptOrders.map(order => {
        if (order.id === selectedCloudOrder.id) {
          return {
            ...order,
            screenshot: reader.result as string,
            paidAt: new Date().toISOString(),
            status: 'paid' as const,
          };
        }
        return order;
      });
      setCloudAdoptOrders(updated);
      saveCloudAdoptOrders(updated);
      setSelectedCloudOrder(prev => prev ? {
        ...prev,
        screenshot: reader.result as string,
        paidAt: new Date().toISOString(),
        status: 'paid' as const,
      } : null);
      setUploadingScreenshot(false);

      const orderData = updated.find(o => o.id === selectedCloudOrder.id);
      if (orderData) {
        sendAdminNotification({
          type: 'cloudAdopt',
          title: '云养订单待审核',
          content: `用户云养了"${orderData.rabbitName}"¥${orderData.amount}，已上传支付凭证，请审核并发放${orderData.cloudCoins}云养币`,
          orderId: selectedCloudOrder.id,
          screenshot: reader.result as string,
        });
      }

      toast.success('凭证上传成功！', {
        description: '管理员审核后云养币将自动到账',
      });
    };
    reader.readAsDataURL(file);
  };

  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr);
    return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')} ${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`;
  };

  const pendingCount = orders.filter(o => o.status === 'pending').length;
  const cloudPendingCount = cloudAdoptOrders.filter(o => o.status === 'pending').length;

  const isDetailView = selectedOrder !== null || selectedCloudOrder !== null;
  const activeTab = selectedOrder ? 'product' : selectedCloudOrder ? 'cloud' : null;

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-2xl max-h-[80vh] overflow-y-auto" showClose={false}>
        <DialogTitle className="text-2xl font-bold text-gray-800 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <ShoppingBag size={24} className="text-pink-600" />
            <span>我的订单</span>
            {(pendingCount + cloudPendingCount) > 0 && (
              <span className="px-2 py-0.5 bg-orange-500 text-white rounded-full text-xs">
                {pendingCount + cloudPendingCount} 待处理
              </span>
            )}
          </div>
          <button onClick={onClose} className="p-1 hover:bg-gray-100 rounded">
            <X size={20} />
          </button>
        </DialogTitle>

        <div className="mt-4">
          {selectedOrder ? (
            // 商品订单详情视图
            <div className="space-y-4">
              <button
                onClick={() => setSelectedOrder(null)}
                className="text-sm text-gray-500 hover:text-gray-800 flex items-center gap-1"
              >
                ← 返回订单列表
              </button>

              {/* 商品信息 */}
              <div className="flex gap-4 items-center bg-gray-50 rounded-lg p-4">
                <div className="w-20 h-20 rounded-lg overflow-hidden flex-shrink-0">
                  <img
                    src={selectedOrder.productImage}
                    alt={selectedOrder.productName}
                    className="w-full h-full object-cover"
                  />
                </div>
                <div className="flex-1">
                  <h3 className="font-semibold text-gray-800">{selectedOrder.productName}</h3>
                  <p className="text-lg font-bold text-pink-600 mt-1">¥{selectedOrder.price}</p>
                </div>
              </div>

              {/* 状态 */}
              <div className="flex items-center gap-2">
                {(() => {
                  const config = getStatusConfig(selectedOrder.status);
                  const Icon = config.icon;
                  return (
                    <span className={`inline-flex items-center gap-1 px-3 py-1.5 rounded-full text-sm font-medium ${config.color}`}>
                      <Icon size={14} />
                      {config.label}
                    </span>
                  );
                })()}
              </div>

              {/* 待上传凭证状态 */}
              {selectedOrder.status === 'pending' && (
                <div className="bg-orange-50 border border-orange-200 rounded-xl p-4">
                  <div className="flex items-start gap-3">
                    <Clock size={20} className="text-orange-500 flex-shrink-0 mt-0.5" />
                    <div className="flex-1">
                      <h4 className="font-semibold text-gray-800 mb-1">请上传支付凭证</h4>
                      <p className="text-sm text-gray-600 mb-3">
                        完成支付后，请在此上传支付截图，管理员确认后将会发货
                      </p>

                      {selectedOrder.screenshot ? (
                        <div className="rounded-lg overflow-hidden border border-gray-200">
                          <img
                            src={selectedOrder.screenshot}
                            alt="支付凭证"
                            className="w-full max-h-48 object-contain bg-white"
                          />
                        </div>
                      ) : (
                        <label className="border-2 border-dashed border-orange-300 rounded-lg p-6 text-center hover:border-orange-400 transition-colors cursor-pointer block">
                          <input
                            type="file"
                            accept="image/*"
                            onChange={handleUploadScreenshot}
                            className="hidden"
                            ref={fileInputRef}
                            disabled={uploadingScreenshot}
                          />
                          <Upload size={28} className="mx-auto text-orange-400 mb-2" />
                          <p className="text-sm text-gray-600">
                            {uploadingScreenshot ? '上传中...' : '点击上传支付截图'}
                          </p>
                        </label>
                      )}

                      {selectedOrder.screenshot && (
                        <Button
                          onClick={() => fileInputRef.current?.click()}
                          variant="outline"
                          size="sm"
                          className="mt-3 border-orange-300 hover:bg-orange-50"
                        >
                          重新上传
                        </Button>
                      )}
                    </div>
                  </div>
                </div>
              )}

              {/* 已上传待发货 */}
              {selectedOrder.status === 'paid' && (
                <div className="bg-blue-50 border border-blue-200 rounded-xl p-4">
                  <div className="flex items-start gap-3">
                    <CheckCircle size={20} className="text-blue-500 flex-shrink-0 mt-0.5" />
                    <div>
                      <h4 className="font-semibold text-gray-800 mb-1">凭证已上传</h4>
                      <p className="text-sm text-gray-600">
                        管理员审核通过后将会发货，请耐心等待
                      </p>
                      <p className="text-xs text-gray-400 mt-2">
                        上传时间：{selectedOrder.paidAt ? formatDate(selectedOrder.paidAt) : '-'}
                      </p>
                    </div>
                  </div>
                  {selectedOrder.screenshot && (
                    <div className="mt-3 rounded-lg overflow-hidden border border-blue-200">
                      <img
                        src={selectedOrder.screenshot}
                        alt="支付凭证"
                        className="w-full max-h-32 object-contain bg-white"
                      />
                    </div>
                  )}
                </div>
              )}

              {/* 已发货 */}
              {selectedOrder.status === 'shipped' && (
                <div className="bg-purple-50 border border-purple-200 rounded-xl p-4">
                  <div className="flex items-start gap-3">
                    <CheckCircle size={20} className="text-purple-500 flex-shrink-0 mt-0.5" />
                    <div>
                      <h4 className="font-semibold text-gray-800 mb-1">商品已发货</h4>
                      <p className="text-sm text-gray-600">
                        商品已发货，请注意查收
                      </p>
                    </div>
                  </div>
                </div>
              )}

              {/* 已完成 */}
              {selectedOrder.status === 'completed' && (
                <div className="bg-green-50 border border-green-200 rounded-xl p-4">
                  <div className="flex items-start gap-3">
                    <CheckCircle size={20} className="text-green-500 flex-shrink-0 mt-0.5" />
                    <div>
                      <h4 className="font-semibold text-gray-800 mb-1">订单已完成</h4>
                      <p className="text-sm text-gray-600">
                        感谢您的爱心支持！
                      </p>
                    </div>
                  </div>
                </div>
              )}

              {/* 订单信息 */}
              <div className="text-xs text-gray-400 space-y-1">
                <p>订单号：{selectedOrder.id}</p>
                <p>下单时间：{formatDate(selectedOrder.createdAt)}</p>
              </div>
            </div>
          ) : selectedCloudOrder ? (
            // 云养订单详情视图
            <div className="space-y-4">
              <button
                onClick={() => setSelectedCloudOrder(null)}
                className="text-sm text-gray-500 hover:text-gray-800 flex items-center gap-1"
              >
                ← 返回订单列表
              </button>

              {/* 云养信息 */}
              <div className="flex gap-4 items-center bg-purple-50 rounded-lg p-4">
                <div className="w-20 h-20 rounded-lg overflow-hidden flex-shrink-0">
                  <img
                    src={selectedCloudOrder.rabbitImage}
                    alt={selectedCloudOrder.rabbitName}
                    className="w-full h-full object-cover"
                  />
                </div>
                <div className="flex-1">
                  <h3 className="font-semibold text-gray-800">云养 {selectedCloudOrder.rabbitName}</h3>
                  <p className="text-lg font-bold text-purple-600 mt-1">¥{selectedCloudOrder.amount}</p>
                  <div className="flex items-center gap-1 text-orange-500 text-sm mt-1">
                    <Coins size={14} />
                    <span>+{selectedCloudOrder.cloudCoins} 云养币</span>
                  </div>
                </div>
              </div>

              {/* 状态 */}
              <div className="flex items-center gap-2">
                {(() => {
                  const config = getCloudStatusConfig(selectedCloudOrder.status);
                  const Icon = config.icon;
                  return (
                    <span className={`inline-flex items-center gap-1 px-3 py-1.5 rounded-full text-sm font-medium ${config.color}`}>
                      <Icon size={14} />
                      {config.label}
                    </span>
                  );
                })()}
              </div>

              {/* 待上传凭证状态 */}
              {selectedCloudOrder.status === 'pending' && (
                <div className="bg-orange-50 border border-orange-200 rounded-xl p-4">
                  <div className="flex items-start gap-3">
                    <Clock size={20} className="text-orange-500 flex-shrink-0 mt-0.5" />
                    <div className="flex-1">
                      <h4 className="font-semibold text-gray-800 mb-1">请上传支付凭证</h4>
                      <p className="text-sm text-gray-600 mb-3">
                        完成支付后，请在此上传支付截图，管理员审核通过后{selectedCloudOrder.cloudCoins}云养币将自动到账
                      </p>

                      {selectedCloudOrder.screenshot ? (
                        <div className="rounded-lg overflow-hidden border border-gray-200">
                          <img
                            src={selectedCloudOrder.screenshot}
                            alt="支付凭证"
                            className="w-full max-h-48 object-contain bg-white"
                          />
                        </div>
                      ) : (
                        <label className="border-2 border-dashed border-orange-300 rounded-lg p-6 text-center hover:border-orange-400 transition-colors cursor-pointer block">
                          <input
                            type="file"
                            accept="image/*"
                            onChange={handleUploadCloudScreenshot}
                            className="hidden"
                            ref={fileInputRef}
                            disabled={uploadingScreenshot}
                          />
                          <Upload size={28} className="mx-auto text-orange-400 mb-2" />
                          <p className="text-sm text-gray-600">
                            {uploadingScreenshot ? '上传中...' : '点击上传支付截图'}
                          </p>
                        </label>
                      )}

                      {selectedCloudOrder.screenshot && (
                        <Button
                          onClick={() => fileInputRef.current?.click()}
                          variant="outline"
                          size="sm"
                          className="mt-3 border-orange-300 hover:bg-orange-50"
                        >
                          重新上传
                        </Button>
                      )}
                    </div>
                  </div>
                </div>
              )}

              {/* 已上传待审核 */}
              {selectedCloudOrder.status === 'paid' && (
                <div className="bg-blue-50 border border-blue-200 rounded-xl p-4">
                  <div className="flex items-start gap-3">
                    <Clock size={20} className="text-blue-500 flex-shrink-0 mt-0.5" />
                    <div>
                      <h4 className="font-semibold text-gray-800 mb-1">凭证已上传</h4>
                      <p className="text-sm text-gray-600">
                        管理员审核通过后{selectedCloudOrder.cloudCoins}云养币将自动到账，请耐心等待
                      </p>
                      <p className="text-xs text-gray-400 mt-2">
                        上传时间：{selectedCloudOrder.paidAt ? formatDate(selectedCloudOrder.paidAt) : '-'}
                      </p>
                    </div>
                  </div>
                  {selectedCloudOrder.screenshot && (
                    <div className="mt-3 rounded-lg overflow-hidden border border-blue-200">
                      <img
                        src={selectedCloudOrder.screenshot}
                        alt="支付凭证"
                        className="w-full max-h-32 object-contain bg-white"
                      />
                    </div>
                  )}
                </div>
              )}

              {/* 已完成 */}
              {selectedCloudOrder.status === 'completed' && (
                <div className="bg-green-50 border border-green-200 rounded-xl p-4">
                  <div className="flex items-start gap-3">
                    <CheckCircle size={20} className="text-green-500 flex-shrink-0 mt-0.5" />
                    <div>
                      <h4 className="font-semibold text-gray-800 mb-1">云养成功</h4>
                      <p className="text-sm text-gray-600">
                        {selectedCloudOrder.cloudCoins}云养币已到账，感谢您的爱心支持！
                      </p>
                    </div>
                  </div>
                </div>
              )}

              {/* 订单信息 */}
              <div className="text-xs text-gray-400 space-y-1">
                <p>订单号：{selectedCloudOrder.id}</p>
                <p>下单时间：{formatDate(selectedCloudOrder.createdAt)}</p>
              </div>
            </div>
          ) : (orders.length === 0 && cloudAdoptOrders.length === 0) ? (
            // 空状态
            <div className="text-center py-16">
              <ShoppingBag size={64} className="mx-auto text-gray-300 mb-4" />
              <h3 className="text-lg font-semibold text-gray-600 mb-2">暂无订单</h3>
              <p className="text-sm text-gray-400 mb-6">快去爱心橱窗或云养兔兔支持一下吧~</p>
            </div>
          ) : (
            // 订单列表（包含商品订单和云养订单）
            <div className="space-y-3">
              {/* 商品订单 */}
              {orders.map((order, index) => {
                const config = getStatusConfig(order.status);
                const Icon = config.icon;
                return (
                  <motion.div
                    key={order.id}
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: index * 0.05 }}
                    onClick={() => setSelectedOrder(order)}
                    className="bg-white border border-gray-200 rounded-xl p-4 cursor-pointer hover:border-pink-300 hover:shadow-md transition-all"
                  >
                    <div className="flex gap-4">
                      <div className="w-16 h-16 rounded-lg overflow-hidden flex-shrink-0">
                        <img
                          src={order.productImage}
                          alt={order.productName}
                          className="w-full h-full object-cover"
                        />
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-start justify-between gap-2">
                          <div>
                            <h3 className="font-semibold text-gray-800 line-clamp-1">
                              {order.productName}
                            </h3>
                            <p className="text-sm text-gray-500 mt-0.5">
                              下单时间：{formatDate(order.createdAt)}
                            </p>
                          </div>
                          <p className="font-bold text-pink-600 flex-shrink-0">¥{order.price}</p>
                        </div>
                        <div className="flex items-center justify-between mt-2">
                          <span className={`inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium ${config.color}`}>
                            <Icon size={12} />
                            {config.label}
                          </span>
                          {order.status === 'pending' && (
                            <span className="text-xs text-orange-500">请上传支付凭证</span>
                          )}
                        </div>
                      </div>
                    </div>
                  </motion.div>
                );
              })}

              {/* 云养订单 */}
              {cloudAdoptOrders.map((order, index) => {
                const config = getCloudStatusConfig(order.status);
                const Icon = config.icon;
                return (
                  <motion.div
                    key={order.id}
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: (orders.length + index) * 0.05 }}
                    onClick={() => setSelectedCloudOrder(order)}
                    className="bg-white border border-purple-200 rounded-xl p-4 cursor-pointer hover:border-purple-400 hover:shadow-md transition-all"
                  >
                    <div className="flex gap-4">
                      <div className="w-16 h-16 rounded-lg overflow-hidden flex-shrink-0">
                        <img
                          src={order.rabbitImage}
                          alt={order.rabbitName}
                          className="w-full h-full object-cover"
                        />
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-start justify-between gap-2">
                          <div>
                            <h3 className="font-semibold text-gray-800 line-clamp-1">
                              云养 {order.rabbitName}
                            </h3>
                            <p className="text-sm text-gray-500 mt-0.5">
                              下单时间：{formatDate(order.createdAt)}
                            </p>
                          </div>
                          <div className="text-right flex-shrink-0">
                            <p className="font-bold text-purple-600">¥{order.amount}</p>
                            <div className="flex items-center gap-1 text-orange-500 text-xs">
                              <Coins size={12} />
                              <span>+{order.cloudCoins}</span>
                            </div>
                          </div>
                        </div>
                        <div className="flex items-center justify-between mt-2">
                          <span className={`inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium ${config.color}`}>
                            <Icon size={12} />
                            {config.label}
                          </span>
                          {order.status === 'pending' && (
                            <span className="text-xs text-orange-500">请上传支付凭证</span>
                          )}
                        </div>
                      </div>
                    </div>
                  </motion.div>
                );
              })}
            </div>
          )}
        </div>
      </DialogContent>
    </Dialog>
  );
}

// 导出添加订单的函数，供其他组件调用
export const addOrder = (order: Omit<Order, 'id' | 'createdAt' | 'status'>) => {
  const orders = loadOrders();
  const newOrder: Order = {
    ...order,
    id: `ORD${Date.now()}`,
    createdAt: new Date().toISOString(),
    status: 'pending',
  };
  orders.unshift(newOrder);
  saveOrders(orders);
  return newOrder;
};
