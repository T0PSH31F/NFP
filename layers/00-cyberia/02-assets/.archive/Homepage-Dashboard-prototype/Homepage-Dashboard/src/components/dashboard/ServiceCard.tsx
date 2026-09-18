import { motion } from 'framer-motion';
import { icons } from 'lucide-react';
import DenDenMushi from './DenDenMushi';
import { type Service, type CrewMember } from '@/data/services';
import { useState } from 'react';

const crewColorMap: Record<CrewMember, string> = {
  luffy: 'hsl(340,100%,50%)',
  zoro: 'hsl(110,100%,54%)',
  nami: 'hsl(35,100%,50%)',
  sanji: 'hsl(51,100%,50%)',
  vegapunk: 'hsl(280,100%,50%)',
  robin: 'hsl(190,100%,50%)',
  chopper: 'hsl(300,100%,50%)',
};

interface ServiceCardProps {
  service: Service;
  index: number;
}

const ServiceCard = ({ service, index }: ServiceCardProps) => {
  const [showYohoho, setShowYohoho] = useState(false);
  const color = crewColorMap[service.category];
  const LucideIcon = (icons as any)[service.icon];
  const isBrook = service.satellite === 'brook';

  return (
    <motion.div
      initial={{ opacity: 0, y: 30, scale: 0.95 }}
      animate={{ opacity: 1, y: 0, scale: 1 }}
      transition={{ delay: index * 0.08, duration: 0.4, ease: 'easeOut' }}
      whileHover={{ y: -4, scale: 1.02 }}
      onClick={() => isBrook && setShowYohoho(v => !v)}
      className="relative group cursor-pointer wanted-watermark overflow-hidden"
      style={{
        animation: 'card-float 4s ease-in-out infinite',
        animationDelay: `${index * 0.3}s`,
      }}
    >
      {/* Neon border glow */}
      <div
        className="absolute inset-0 rounded-lg opacity-40 group-hover:opacity-70 transition-opacity duration-300 shimmer-border"
        style={{
          background: `linear-gradient(90deg, transparent, ${color}40, transparent, ${color}20, transparent)`,
          padding: '1px',
        }}
      />
      {/* Glass card */}
      <div
        className="relative rounded-lg border backdrop-blur-xl p-4 h-full"
        style={{
          backgroundColor: 'hsl(240 50% 10% / 0.7)',
          borderColor: `${color}30`,
          clipPath: 'polygon(0 0, 98% 0, 100% 3%, 100% 97%, 99% 100%, 2% 100%, 0 98%, 0 2%)',
        }}
      >
        {/* Brook floating notes */}
        {isBrook && (
          <div className="absolute inset-0 pointer-events-none overflow-hidden">
            {['♪', '♫', '♪', '♫'].map((note, i) => (
              <span
                key={i}
                className="absolute text-lg"
                style={{
                  left: `${20 + i * 20}%`,
                  bottom: '10%',
                  color: '#f5f5dc',
                  opacity: 0.6,
                  animation: `float-note 2.5s ease-out infinite`,
                  animationDelay: `${i * 0.6}s`,
                }}
              >
                {note}
              </span>
            ))}
          </div>
        )}

        {/* Header row */}
        <div className="flex items-start justify-between mb-3">
          <div className="flex items-center gap-3">
            {/* Service icon */}
            <div
              className="p-2 rounded-lg"
              style={{
                backgroundColor: `${color}15`,
                boxShadow: `0 0 12px ${color}30`,
                animation: 'card-float 3s ease-in-out infinite',
              }}
            >
              {LucideIcon && <LucideIcon size={28} style={{ color }} />}
            </div>
            <div>
              <h3 className="font-exo font-semibold text-sm leading-tight" style={{ color }}>
                {service.name}
              </h3>
              <p className="text-[10px] font-space text-muted-foreground mt-0.5">{service.subtitle}</p>
              {service.satellite && (
                <span className="text-[9px] font-orbitron uppercase tracking-widest" style={{ color: `${color}80` }}>
                  {service.satellite === 'stella' ? '★ Stella' : `◆ ${service.satellite}`}
                </span>
              )}
            </div>
          </div>
          <DenDenMushi status={service.status} size={22} hasAfro={isBrook} />
        </div>

        {/* Stats */}
        {service.stats && (
          <div className="grid grid-cols-2 gap-x-3 gap-y-1 mb-3">
            {Object.entries(service.stats).map(([key, val]) => (
              <div key={key} className="flex items-center gap-1.5">
                <span className="text-[10px] text-muted-foreground uppercase font-space">{key}</span>
                <span className="text-[11px] font-exo font-medium" style={{ color }}>{val}</span>
              </div>
            ))}
          </div>
        )}

        {/* Bounty footer */}
        <div
          className="rounded px-2 py-1.5 text-center"
          style={{ backgroundColor: `${color}10`, borderTop: `1px solid ${color}20` }}
        >
          <span className="font-orbitron text-[11px] font-bold tracking-wider" style={{ color }}>
            {service.bountyLabel}
          </span>
        </div>

        {/* Action buttons */}
        <div className="flex gap-2 mt-3">
          <a
            href={service.url}
            className="flex-1 text-center py-1.5 rounded text-[10px] font-orbitron font-bold uppercase tracking-wider transition-all hover:brightness-125"
            style={{ backgroundColor: `${color}20`, color, border: `1px solid ${color}30` }}
          >
            Board Ship
          </a>
          <button
            className="px-3 py-1.5 rounded text-[10px] font-orbitron uppercase tracking-wider transition-all hover:brightness-125"
            style={{ backgroundColor: 'hsl(240 50% 15% / 0.5)', color: 'hsl(215 20% 65%)', border: '1px solid hsl(260 30% 25%)' }}
          >
            Logs
          </button>
        </div>

        {/* Brook Yohohoho bubble */}
        {isBrook && showYohoho && (
          <motion.div
            initial={{ opacity: 0, scale: 0.8, y: 10 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0 }}
            className="absolute -top-8 right-2 px-3 py-1 rounded-full text-xs font-orbitron"
            style={{ backgroundColor: '#f5f5dc', color: '#1a0a2e' }}
          >
            Yohohoho! 💀🎵
          </motion.div>
        )}
      </div>
    </motion.div>
  );
};

export default ServiceCard;
