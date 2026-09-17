import { motion } from 'framer-motion';
import { type Category } from '@/data/services';
import ServiceCard from './ServiceCard';

import luffyImg from '@/assets/luffy.png';
import zoroImg from '@/assets/zoro.png';
import namiImg from '@/assets/nami.png';
import sanjiImg from '@/assets/sanji.png';
import robinImg from '@/assets/robin.png';
import chopperImg from '@/assets/chopper.png';

const crewImages: Record<string, string> = {
  luffy: luffyImg,
  zoro: zoroImg,
  nami: namiImg,
  sanji: sanjiImg,
  robin: robinImg,
  chopper: chopperImg,
};

interface CategorySectionProps {
  category: Category;
  searchQuery: string;
}

const CategorySection = ({ category, searchQuery }: CategorySectionProps) => {
  const filtered = category.services.filter(s =>
    s.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    s.subtitle.toLowerCase().includes(searchQuery.toLowerCase())
  );

  if (filtered.length === 0) return null;

  const crewImage = crewImages[category.id];

  return (
    <motion.section
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      className="mb-10"
    >
      {/* Vivre Card Header */}
      <div
        className="relative mb-6 p-4 rounded-lg border backdrop-blur-md overflow-hidden"
        style={{
          backgroundColor: 'hsl(240 50% 8% / 0.6)',
          borderColor: 'hsl(var(--border))',
          clipPath: 'polygon(0 0, 97% 0, 100% 30%, 100% 100%, 3% 100%, 0 70%)',
        }}
      >
        {/* Burning corner glow */}
        <div
          className="absolute top-0 right-0 w-16 h-16 rounded-bl-full opacity-30"
          style={{
            background: `radial-gradient(circle at top right, ${category.colorClass === 'text-crew-luffy' ? 'hsl(340,100%,50%)' : 'currentColor'}, transparent)`,
          }}
        />
        <div className="flex items-center gap-3">
          {crewImage ? (
            <img src={crewImage} alt={category.name} className="w-10 h-10 object-contain rounded-full" />
          ) : (
            <span className="text-2xl">{category.emoji}</span>
          )}
          <div>
            <h2 className={`font-orbitron text-lg font-bold tracking-wider uppercase ${category.neonClass}`}>
              {category.name}
            </h2>
            <p className="text-xs font-exo text-muted-foreground tracking-wide uppercase mt-0.5">
              — {category.subtitle}
            </p>
          </div>
          <div className="ml-auto flex items-center gap-2">
            <span className="text-[10px] font-orbitron text-muted-foreground">
              {filtered.length}/{category.services.length} ACTIVE
            </span>
          </div>
        </div>
      </div>

      {/* Service cards grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
        {filtered.map((service, i) => (
          <ServiceCard key={service.id} service={service} index={i} />
        ))}
      </div>
    </motion.section>
  );
};

export default CategorySection;
