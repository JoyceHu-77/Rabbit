import { useState } from 'react';
import { motion } from 'motion/react';
import { Button } from '../ui/button';
import { ShoppingBag, Award, Coins, QrCode, Settings } from 'lucide-react';
import { rabbitDatabase } from '../../../data/rabbitData';
import PurchaseDialog from './PurchaseDialog';
import QRCodesDialog from './QRCodesDialog';

// 使用真实的兔兔数据（排除"已去世"和"已领养"状态）
const products = rabbitDatabase
  .filter(rabbit => rabbit.status !== '已去世' && rabbit.status !== '已领养')
  .map(rabbit => ({
    id: rabbit.id,
    name: `${rabbit.name}的电子照片`,
    rabbit: rabbit.name,
    image: rabbit.photo,
    description: `云养${rabbit.name}兔兔，购买后可获取该兔兔对应照片。您的一点心意将全部用于购置当前兔兔的生活用品、粮草、药物等，感谢您的支持！`,
    price: 5,
    badges: 1,
    cloudCoins: 5,
  }));

interface CharityShopProps {
  isAdmin: boolean;
}

export default function CharityShop({ isAdmin }: CharityShopProps) {
  const [showPurchaseDialog, setShowPurchaseDialog] = useState(false);
  const [selectedProduct, setSelectedProduct] = useState<typeof products[0] | null>(null);
  const [purchaseMode, setPurchaseMode] = useState<'purchase' | 'badge' | 'coin'>('purchase');
  const [showQRCodes, setShowQRCodes] = useState(false);

  const handlePurchase = (product: typeof products[0]) => {
    setSelectedProduct(product);
    setPurchaseMode('purchase');
    setShowPurchaseDialog(true);
  };

  const handleExchange = (product: typeof products[0], type: 'badge' | 'coin') => {
    setSelectedProduct(product);
    setPurchaseMode(type);
    setShowPurchaseDialog(true);
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="text-center flex-1">
          <h2 className="text-2xl font-bold text-gray-800 mb-2">爱兔会爱心橱窗</h2>
          <p className="text-gray-600 text-sm">
            您的一点心意将全部用于购置兔兔的生活用品、粮草、药物等
          </p>
        </div>
        {isAdmin && (
          <button
            onClick={() => setShowQRCodes(true)}
            className="flex-shrink-0 p-2 bg-pink-100 hover:bg-pink-200 rounded-full transition-colors"
            title="管理收款二维码"
          >
            <Settings size={18} className="text-pink-600" />
          </button>
        )}
      </div>

      <div className="grid grid-cols-2 gap-4">
        {products.map((product, index) => (
          <motion.div
            key={product.id}
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: index * 0.1 }}
            className="bg-white rounded-xl overflow-hidden shadow-md hover:shadow-lg transition-shadow"
          >
            <div className="aspect-square relative">
              <img
                src={product.image}
                alt={product.name}
                className="w-full h-full object-cover"
              />
            </div>

            <div className="p-3 space-y-2">
              <h3 className="font-bold text-sm text-gray-800 line-clamp-1">
                {product.name}
              </h3>

              <p className="text-xs text-gray-600 line-clamp-2">
                {product.description}
              </p>

              <div className="flex items-center justify-between text-xs">
                <span className="text-pink-600 font-semibold">¥{product.price}</span>
                <div className="flex gap-2 text-gray-500">
                  <span className="flex items-center gap-1">
                    <Award size={12} />×{product.badges}
                  </span>
                  <span className="flex items-center gap-1">
                    <Coins size={12} />×{product.cloudCoins}
                  </span>
                </div>
              </div>

              <div className="space-y-1.5">
                <Button
                  size="sm"
                  onClick={() => handlePurchase(product)}
                  className="w-full bg-gradient-to-r from-pink-500 to-orange-500 hover:from-pink-600 hover:to-orange-600 text-xs h-8"
                >
                  <ShoppingBag size={12} className="mr-1" />
                  购买
                </Button>

                <div className="flex gap-1.5">
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() => handleExchange(product, 'badge')}
                    className="flex-1 text-xs h-7 border-pink-200 hover:bg-pink-50"
                  >
                    奖章兑换
                  </Button>
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() => handleExchange(product, 'coin')}
                    className="flex-1 text-xs h-7 border-purple-200 hover:bg-purple-50"
                  >
                    云养币兑换
                  </Button>
                </div>
              </div>
            </div>
          </motion.div>
        ))}
      </div>

      <div className="bg-gradient-to-br from-pink-50 to-orange-50 rounded-xl p-6 border border-pink-200">
        <h3 className="font-semibold text-gray-800 mb-3">兑换说明</h3>
        <ul className="text-sm text-gray-600 space-y-2">
          <li className="flex items-start gap-2">
            <span className="text-pink-500">•</span>
            <span>1枚爱兔奖章 = 5个云养币 = ¥5元</span>
          </li>
          <li className="flex items-start gap-2">
            <span className="text-pink-500">•</span>
            <span>购买后系统自动发货至个人页</span>
          </li>
          <li className="flex items-start gap-2">
            <span className="text-pink-500">•</span>
            <span>所有收入用于兔兔的生活照护</span>
          </li>
        </ul>
      </div>

      {/* 购买/兑换对话框 */}
      <PurchaseDialog
        open={showPurchaseDialog}
        onClose={() => {
          setShowPurchaseDialog(false);
          setSelectedProduct(null);
        }}
        product={selectedProduct}
        mode={purchaseMode}
      />

      {/* 管理员二维码管理对话框 */}
      <QRCodesDialog
        open={showQRCodes}
        onClose={() => setShowQRCodes(false)}
      />
    </div>
  );
}
