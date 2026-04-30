"use client";

import { motion } from 'motion/react';

export default function RabbitLoading() {
  return (
    <div className="flex flex-col items-center justify-center py-20">
      <div className="relative">
        {/* 兔兔 */}
        <motion.div
          animate={{
            y: [0, -5, 0],
          }}
          transition={{
            duration: 1,
            repeat: Infinity,
            ease: "easeInOut"
          }}
          className="relative"
        >
          {/* 兔兔身体 */}
          <div className="text-6xl">🐰</div>
          {/* 左耳 */}
          <div className="absolute -top-2 -left-2 text-3xl origin-bottom -rotate-12">
            🐰
          </div>
          {/* 胡萝卜 */}
          <motion.div
            animate={{
              rotate: [-10, 10, -10],
            }}
            transition={{
              duration: 0.5,
              repeat: Infinity,
              ease: "easeInOut"
            }}
            className="absolute -bottom-2 -right-2 text-3xl origin-top"
          >
            🥕
          </motion.div>
        </motion.div>
      </div>
      <motion.div
        animate={{ opacity: [0.5, 1, 0.5] }}
        transition={{ duration: 1.5, repeat: Infinity }}
        className="mt-6 text-gray-500 text-sm"
      >
        兔兔正在努力加载中...
      </motion.div>
    </div>
  );
}
