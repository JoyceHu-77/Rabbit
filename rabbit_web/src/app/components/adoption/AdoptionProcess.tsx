import { motion } from 'motion/react';
import { CheckCircle2, Gift, Heart, FileText, Home, Package } from 'lucide-react';
import { Button } from '../ui/button';
import giftPackageImg from '../../../imports/爱兔会合作-饲养礼包.png';

const benefits = [
  {
    icon: Gift,
    title: '首月领养礼包',
    items: [
      { label: '收助者', desc: '免费获取粮草、兔粮包等，减轻初期养护负担' },
      { label: '领养人', desc: '免费救护车服务、兔粮赠品分享' },
    ],
    color: 'from-pink-500 to-rose-500',
  },
  {
    icon: Heart,
    title: '礼包内容',
    items: [
      { label: '兔粮', desc: '小佩鸭、速溶胡萝卜' },
      { label: '玩具', desc: '咬胶、草编球' },
      { label: '装备', desc: '厕所训练、宠粮剩余' },
      { label: '医疗券', desc: '年费、草药袋等' },
      { label: '其他商品', desc: '其他合作商精选礼包' },
    ],
    color: 'from-red-500 to-rose-500',
  },
];

const steps = [
  '浏览寄养中的兔兔',
  '提交领养意向问卷',
  '管理员审核',
  '缴纳押金',
  '带兔兔回家',
  '定期回访',
  '申请退还押金',
];

export default function AdoptionProcess() {
  return (
    <div className="space-y-8">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="bg-gradient-to-br from-pink-100 to-purple-100 rounded-2xl p-6"
      >
        <h2 className="text-2xl font-bold text-purple-800 mb-4">为什么要领养？</h2>
        <div className="space-y-3 text-gray-700">
          <p className="leading-relaxed">
            每一只流浪兔都曾经历过被遗弃的痛苦。通过领养，您不仅为它们提供了第二次生命的机会，更传递了爱与责任。
          </p>
          <p className="leading-relaxed">
            领养代替购买，让更多人关注流浪动物问题，共同营造一个更有爱的社会。
          </p>
        </div>
      </motion.div>

      <div>
        <h2 className="text-xl font-bold text-gray-800 mb-4">领养流程</h2>
        <div className="space-y-3">
          {steps.map((step, index) => (
            <motion.div
              key={index}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: index * 0.1 }}
              className="flex items-center gap-4 bg-white rounded-xl p-4 shadow-sm"
            >
              <div className="flex-shrink-0 w-8 h-8 rounded-full bg-gradient-to-br from-red-500 to-rose-500 text-white flex items-center justify-center font-semibold text-sm">
                {index + 1}
              </div>
              <span className="text-gray-700">{step}</span>
            </motion.div>
          ))}
        </div>
      </div>

      <div>
        <h2 className="text-xl font-bold text-gray-800 mb-4 flex items-center gap-2">
          <Package className="text-red-600" />
          领养后享受的权益
        </h2>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-white rounded-2xl overflow-hidden shadow-md mb-6"
        >
          <img
            src={giftPackageImg}
            alt="首月饲养礼包"
            className="w-full h-auto object-contain"
          />
        </motion.div>

        <div className="grid gap-6">
          {benefits.map((benefit, index) => {
            const Icon = benefit.icon;
            return (
              <motion.div
                key={index}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: index * 0.2 }}
                className="bg-white rounded-2xl overflow-hidden shadow-md"
              >
                <div
                  className={`bg-gradient-to-r ${benefit.color} text-white px-6 py-4 flex items-center gap-3`}
                >
                  <Icon size={24} />
                  <h3 className="text-lg font-semibold">{benefit.title}</h3>
                </div>
                <div className="p-6 space-y-3">
                  {benefit.items.map((item, i) => (
                    <div key={i} className="flex gap-3">
                      <div className="flex-shrink-0 w-6 h-6 rounded-full bg-red-100 flex items-center justify-center">
                        <CheckCircle2 size={14} className="text-red-600" />
                      </div>
                      <div>
                        <span className="font-medium text-gray-800">{item.label}</span>
                        {item.desc && (
                          <p className="text-sm text-gray-600 mt-0.5">{item.desc}</p>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </motion.div>
            );
          })}
        </div>
      </div>

      <div className="bg-gradient-to-br from-orange-100 to-pink-100 rounded-2xl p-6">
        <h2 className="text-xl font-bold text-gray-800 mb-4 flex items-center gap-2">
          <Home size={24} className="text-orange-600" />
          领养社区
        </h2>
        <p className="text-gray-700 mb-4">
          查看所有待领养的兔兔，提交领养申请，开启您的爱心之旅。
        </p>
        <Button className="bg-gradient-to-r from-red-500 to-rose-500 hover:from-purple-600 hover:to-pink-600 w-full">
          查看待领养兔兔
        </Button>
      </div>
    </div>
  );
}
