import { useState } from 'react';
import { motion } from 'motion/react';
import { Heart, BookOpen, MessageCircle, Award } from 'lucide-react';
import { Button } from '../ui/button';
import AdoptionProcess from './AdoptionProcess';
import RabbitStorybook from './RabbitStorybook';
import AdoptionCommunity from './AdoptionCommunity';

interface AdoptionTabProps {
  isAdmin: boolean;
}

type SectionType = 'process' | 'storybook' | 'community';

export default function AdoptionTab({ isAdmin }: AdoptionTabProps) {
  const [activeSection, setActiveSection] = useState<SectionType>('process');

  const sections = [
    { id: 'process', label: '领养流程', icon: Heart },
    { id: 'storybook', label: '兔兔故事书', icon: BookOpen },
    { id: 'community', label: '领养社区', icon: MessageCircle },
  ] as const;

  return (
    <div className="min-h-screen pb-6">
      <div className="bg-gradient-to-br from-red-500 to-rose-500 text-white px-6 py-8">
        <h1 className="text-3xl font-bold mb-2">爱兔领养</h1>
        <p className="text-white/90 text-sm">给每只兔兔一个温暖的家</p>
      </div>

      <div className="sticky top-0 bg-white border-b border-purple-100 shadow-sm z-10">
        <div className="flex items-center max-w-2xl mx-auto overflow-x-auto">
          {sections.map((section) => {
            const Icon = section.icon;
            const isActive = activeSection === section.id;

            return (
              <button
                key={section.id}
                onClick={() => setActiveSection(section.id as SectionType)}
                className={`flex-1 min-w-[100px] py-4 px-4 flex flex-col items-center gap-1 relative ${
                  isActive ? 'text-purple-600' : 'text-gray-500'
                }`}
              >
                {isActive && (
                  <motion.div
                    layoutId="activeSection"
                    className="absolute bottom-0 left-0 right-0 h-0.5 bg-gradient-to-r from-red-500 to-rose-500"
                  />
                )}
                <Icon size={20} />
                <span className="text-xs font-medium">{section.label}</span>
              </button>
            );
          })}
        </div>
      </div>

      <div className="max-w-2xl mx-auto px-4 py-6">
        {activeSection === 'process' && <AdoptionProcess />}
        {activeSection === 'storybook' && <RabbitStorybook />}
        {activeSection === 'community' && <AdoptionCommunity isAdmin={isAdmin} />}
      </div>
    </div>
  );
}
