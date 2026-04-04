interface CommunityHeroProps {
  communityName: string;
  memberCount: string;
  repositoryType: string;
  bannerSrc: string;
  iconSrc: string;
}

export default function CommunityHero({
  communityName,
  memberCount,
  repositoryType,
  bannerSrc,
  iconSrc,
}: CommunityHeroProps) {
  return (
    <div className="relative h-[192px] w-full overflow-hidden bg-surface-raised">
      <img
        src={bannerSrc}
        alt=""
        className="absolute inset-0 h-full w-full object-cover opacity-40"
      />
      <div className="absolute inset-0 bg-linear-to-t from-surface-base to-transparent"></div>
      <div className="absolute bottom-0 left-0 right-0 flex items-end justify-between p-8">
        <div className="flex items-center gap-6">
          <img
            src={iconSrc}
            alt={communityName}
            className="size-[80px] rounded-sm border-4 border-surface-base bg-surface-input p-1"
          />
          <div className="flex flex-col gap-1">
            <h1 className="text-[30px] font-bold leading-9 tracking-tight text-text-primary">
              {communityName}
            </h1>
            <div className="flex items-center gap-2 text-sm text-text-secondary">
              <span>{memberCount}</span>
              <span className="text-text-muted">•</span>
              <span>{repositoryType}</span>
            </div>
          </div>
        </div>
        <button className="rounded-sm bg-surface-overlay px-6 py-2.5 text-base font-semibold text-text-primary">
          Join
        </button>
      </div>
    </div>
  );
}
