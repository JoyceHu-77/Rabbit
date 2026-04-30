import { useState } from 'react';
import { motion } from 'motion/react';
import { Button } from '../ui/button';
import { Award, Calendar, Upload } from 'lucide-react';
import { toast } from 'sonner';

export default function CheckinActivity() {
  const [status, setStatus] = useState<'未参与' | '参与中' | '待上传'>('未参与');
  const [daysLeft, setDaysLeft] = useState(7);
  const [badges, setBadges] = useState(0);

  const handleJoin = () => {
    setStatus('参与中');
    setDaysLeft(7);
    toast.success('参与成功！', {
      description: '开始您的7天善事记录之旅吧',
    });
  };

  const handleUpload = () => {
    setBadges(badges + 1);
    setStatus('未参与');
    toast.success('上传成功！', {
      description: '恭喜您获得一枚爱兔奖章',
    });
  };

  return (
    <div className="space-y-6">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="bg-gradient-to-br from-pink-100 to-rose-100 rounded-2xl p-6"
      >
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-2xl font-bold text-pink-800">只取心滴</h2>
          <Award size={32} className="text-pink-600" />
        </div>

        <p className="text-gray-700 mb-6 leading-relaxed">
          点击参与活动后，7天内可记录每日善事（如喂流浪猫、给环卫工人送水并拍照）。
          期满后上传7日善事及配图，即可获得爱兔奖章一枚，用于兑换橱窗奖品（如中药手环、草药袋等）。
        </p>

        <div className="bg-white rounded-xl p-4 mb-6">
          <h3 className="font-semibold text-gray-800 mb-3">活动规则</h3>
          <ul className="text-sm text-gray-600 space-y-2">
            <li className="flex items-start gap-2">
              <span className="text-pink-500">•</span>
              <span>每天记录一件善事，可拍照留存</span>
            </li>
            <li className="flex items-start gap-2">
              <span className="text-pink-500">•</span>
              <span>7天完成后上传所有善事记录</span>
            </li>
            <li className="flex items-start gap-2">
              <span className="text-pink-500">•</span>
              <span>邀请好友一起参与，双方各获赠一枚奖章</span>
            </li>
          </ul>
        </div>

        {status === '未参与' && (
          <Button
            onClick={handleJoin}
            className="w-full bg-gradient-to-r from-pink-500 to-rose-500 hover:from-pink-600 hover:to-rose-600"
          >
            点击参与
          </Button>
        )}

        {status === '参与中' && (
          <div className="text-center">
            <div className="inline-flex items-center gap-2 px-4 py-2 bg-white rounded-full mb-4">
              <Calendar size={20} className="text-pink-600" />
              <span className="font-semibold text-gray-800">
                还剩 {daysLeft} 天
              </span>
            </div>
            <p className="text-sm text-gray-600 mb-2">继续加油！记录您的善举</p>
            {daysLeft === 0 ? (
              <>
                <p className="text-sm text-green-600 font-medium mb-4">恭喜完成7天善事记录！</p>
                <Button
                  onClick={() => setStatus('待上传')}
                  className="w-full bg-gradient-to-r from-pink-500 to-rose-500 hover:from-pink-600 hover:to-rose-600"
                >
                  上传物料领取奖章
                </Button>
              </>
            ) : (
              <p className="text-xs text-gray-400">时间到后可上传物料领取奖章</p>
            )}
          </div>
        )}

        {status === '待上传' && (
          <div>
            <div className="border-2 border-dashed border-pink-300 rounded-xl p-8 text-center mb-4">
              <Upload size={40} className="mx-auto text-pink-400 mb-2" />
              <p className="text-sm text-gray-600">上传您的7日善事及配图</p>
            </div>
            <Button
              onClick={handleUpload}
              className="w-full bg-gradient-to-r from-pink-500 to-rose-500 hover:from-pink-600 hover:to-rose-600"
            >
              上传物料
            </Button>
          </div>
        )}
      </motion.div>

      <div className="bg-white rounded-2xl p-6 shadow-md">
        <h3 className="font-semibold text-gray-800 mb-4 flex items-center gap-2">
          <Award size={20} className="text-pink-600" />
          我的爱兔奖章
        </h3>
        <div className="text-center py-8">
          <div className="text-4xl font-bold text-pink-600 mb-2">{badges}</div>
          <p className="text-sm text-gray-500">枚奖章</p>
        </div>
        <Button
          variant="outline"
          className="w-full border-pink-300 hover:bg-pink-50"
        >
          去兑换礼品
        </Button>
      </div>
    </div>
  );
}
