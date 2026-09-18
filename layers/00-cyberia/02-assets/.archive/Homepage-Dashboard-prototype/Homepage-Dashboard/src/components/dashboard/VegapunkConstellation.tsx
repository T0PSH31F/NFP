import { motion } from 'framer-motion';
import { type Service } from '@/data/services';
import ServiceCard from './ServiceCard';
import { useState } from 'react';
import vegapunkImg from '@/assets/vegapunk.png';
import stellaImg from '@/assets/stella.png';

const satellitePositions = [
  { angle: 0, label: 'Shaka' },
  { angle: 51, label: 'Edison' },
  { angle: 103, label: 'Lilith' },
  { angle: 154, label: 'Pythagoras' },
  { angle: 206, label: 'Brook' },
  { angle: 257, label: 'York' },
  { angle: 309, label: 'Atlas' },
];

interface VegapunkConstellationProps {
  services: Service[];
  searchQuery: string;
}

const VegapunkConstellation = ({ services, searchQuery }: VegapunkConstellationProps) => {
  const [hoveredSatellite, setHoveredSatellite] = useState<string | null>(null);
  const stella = services.find(s => s.satellite === 'stella');
  const satellites = services.filter(s => s.satellite && s.satellite !== 'stella');
  const filtered = services.filter(s =>
    s.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    s.subtitle.toLowerCase().includes(searchQuery.toLowerCase())
  );

  if (filtered.length === 0) return null;

  return (
    <motion.section
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      className="mb-10"
    >
      {/* Header */}
      <div
        className="relative mb-6 p-4 rounded-lg border backdrop-blur-md overflow-hidden"
        style={{
          backgroundColor: 'hsl(240 50% 8% / 0.6)',
          borderColor: 'hsl(var(--border))',
          clipPath: 'polygon(0 0, 97% 0, 100% 30%, 100% 100%, 3% 100%, 0 70%)',
        }}
      >
        <div className="flex items-center gap-3">
          <img src={vegapunkImg} alt="Vegapunk" className="w-10 h-10 object-contain rounded-full" />
          <div>
            <h2 className="font-orbitron text-lg font-bold tracking-wider uppercase neon-text-purple">
              Vegapunk Records
            </h2>
            <p className="text-xs font-exo text-muted-foreground tracking-wide uppercase mt-0.5">
              — Satellite Network
            </p>
          </div>
          <div className="ml-auto text-[10px] font-orbitron text-muted-foreground">
            {satellites.length + 1} SATELLITES ACTIVE
          </div>
        </div>
      </div>

      {/* Constellation visual - desktop only */}
      <div className="hidden lg:flex justify-center mb-8">
        <div className="relative" style={{ width: 420, height: 420 }}>
          {/* Connection lines */}
          <svg className="absolute inset-0" viewBox="0 0 420 420" width={420} height={420}>
            {satellites.map((sat, i) => {
              const pos = satellitePositions[i];
              if (!pos) return null;
              const rad = (pos.angle * Math.PI) / 180;
              const x = 210 + Math.cos(rad) * 160;
              const y = 210 + Math.sin(rad) * 160;
              return (
                <line
                  key={sat.id}
                  x1={210} y1={210} x2={x} y2={y}
                  stroke="hsl(280,100%,50%)"
                  strokeWidth={hoveredSatellite === sat.id ? 2 : 0.5}
                  opacity={hoveredSatellite === sat.id ? 0.8 : 0.15}
                  className="transition-all duration-300"
                />
              );
            })}
          </svg>

          {/* Stella center */}
          {stella && (
            <div className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 z-10">
              <div
                className="w-20 h-20 rounded-full flex items-center justify-center overflow-hidden"
                style={{
                  background: 'radial-gradient(circle, hsl(280,100%,50%,0.3), hsl(280,100%,50%,0.05))',
                  boxShadow: '0 0 30px hsl(280,100%,50%,0.4), 0 0 60px hsl(280,100%,50%,0.15)',
                  animation: 'jolly-pulse 3s ease-in-out infinite',
                }}
              >
                <img src={stellaImg} alt="Stella" className="w-16 h-16 object-contain" />
              </div>
              <p className="text-center text-[9px] font-orbitron text-crew-vegapunk mt-1 uppercase tracking-widest">Stella</p>
            </div>
          )}

          {/* Satellite nodes */}
          {satellites.map((sat, i) => {
            const pos = satellitePositions[i];
            if (!pos) return null;
            const rad = (pos.angle * Math.PI) / 180;
            const x = 210 + Math.cos(rad) * 160;
            const y = 210 + Math.sin(rad) * 160;

            const personalityEmoji: Record<string, string> = {
              shaka: '😇', lilith: '😈', brook: '💀', edison: '💡', pythagoras: '📐', york: '🤑', atlas: '💪',
            };

            return (
              <motion.div
                key={sat.id}
                className="absolute z-10 cursor-pointer"
                style={{ left: x - 24, top: y - 24 }}
                onMouseEnter={() => setHoveredSatellite(sat.id)}
                onMouseLeave={() => setHoveredSatellite(null)}
                whileHover={{ scale: 1.2 }}
              >
                <div
                  className="w-12 h-12 rounded-full flex items-center justify-center text-xl border"
                  style={{
                    backgroundColor: 'hsl(240 50% 10% / 0.8)',
                    borderColor: 'hsl(280,100%,50%,0.4)',
                    boxShadow: hoveredSatellite === sat.id ? '0 0 20px hsl(280,100%,50%,0.6)' : '0 0 8px hsl(280,100%,50%,0.2)',
                  }}
                >
                  {personalityEmoji[sat.satellite!] || '◆'}
                </div>
                <p className="text-center text-[8px] font-orbitron text-muted-foreground mt-1 uppercase tracking-wider">
                  {sat.satellite}
                </p>
              </motion.div>
            );
          })}
        </div>
      </div>

      {/* Cards grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
        {filtered.map((service, i) => (
          <ServiceCard key={service.id} service={service} index={i} />
        ))}
      </div>
    </motion.section>
  );
};

export default VegapunkConstellation;
