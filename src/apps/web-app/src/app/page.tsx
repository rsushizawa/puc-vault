import NavBar from "@/components/navbar";
import CommunityHero from "@/components/community-hero";
export default function Home() {
  const defaultProps = {
    communityName: "Engenharia da Computação",
    memberCount: "12.4k",
    repositoryType: "PUC repositotyType",
    bannerSrc: "/banner.jpg",
    iconSrc: "/icon.png",
  };
  return (
    <div className="bg-surface-base min-h-screen flex flex-col">
      <NavBar />
      <main>
        <CommunityHero {...defaultProps}></CommunityHero>
      </main>
    </div>
  );
}
