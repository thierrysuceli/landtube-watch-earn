import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Star, Play, CheckCircle2, Hourglass, Trophy } from "lucide-react";
import { toast } from "sonner";
import { CompletionModal } from "@/components/CompletionModal";
import { SimpleYouTubePlayer } from "@/components/SimpleYouTubePlayer";

interface Video {
  id: string;
  title: string;
  thumbnail_url: string | null;
  youtube_url?: string;
  duration: number | null;
  earning_amount: number | null;
  is_active: boolean | null;
  created_at: string | null;
}

interface Review {
  video_id: string;
  rating: number;
}

const Review = () => {
  const navigate = useNavigate();
  const [videos, setVideos] = useState<Video[]>([]);
  const [currentIndex, setCurrentIndex] = useState(0);
  const [rating, setRating] = useState(0);
  const [hoverRating, setHoverRating] = useState(0);
  const [hasWatched, setHasWatched] = useState(false);
  const [reviews, setReviews] = useState<Review[]>([]);
  const [loading, setLoading] = useState(true);
  const [userId, setUserId] = useState<string>("");
  const [showCompletion, setShowCompletion] = useState(false);
  const [totalEarnings, setTotalEarnings] = useState(0);
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    loadVideos();
  }, []);

  const loadVideos = async () => {
    try {
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) {
        navigate("/auth");
        return;
      }

      setUserId(session.user.id);

      // Get user's profile to check daily reviews
      const { data: profile } = await supabase
        .from("profiles")
        .select("daily_reviews_completed")
        .eq("user_id", session.user.id)
        .single();

      if (profile && profile.daily_reviews_completed >= 5) {
        toast.info("You've already completed your daily reviews!");
        navigate("/dashboard");
        return;
      }

      // Step 1: Get IDs of videos already reviewed by this user
      const { data: reviewedVideos } = await supabase
        .from("reviews")
        .select("video_id")
        .eq("user_id", session.user.id);

      const reviewedVideoIds = reviewedVideos?.map((r) => r.video_id) || [];

      // Step 2: Get all active videos (to randomize on client side)
      let query = supabase
        .from("videos")
        .select("*")
        .eq("is_active", true);

      // Step 3: Exclude already reviewed videos
      if (reviewedVideoIds.length > 0) {
        query = query.not("id", "in", `(${reviewedVideoIds.join(",")})`);
      }

      const { data: availableVideos, error } = await query;

      if (error) throw error;

      // Step 4: Check if there are enough videos
      if (!availableVideos || availableVideos.length === 0) {
        toast.info("You've already reviewed all available videos!");
        navigate("/dashboard");
        return;
      }

      // Step 5: Shuffle videos randomly and pick up to 5
      const shuffled = availableVideos.sort(() => Math.random() - 0.5);
      const selectedVideos = shuffled.slice(0, 5);

      setVideos(selectedVideos);
    } catch (error) {
      toast.error("Error loading videos");
      navigate("/dashboard");
    } finally {
      setLoading(false);
    }
  };

  const handleWatchComplete = () => {
    setHasWatched(true);
  };

  const handleRateAndNext = async () => {
    // Prevenir múltiplos cliques
    if (isSubmitting) {
      return;
    }

    if (rating === 0) {
      toast.error("Please select a rating");
      return;
    }

    // Bloquear botão durante processamento
    setIsSubmitting(true);

    const newReviews = [
      ...reviews,
      { video_id: videos[currentIndex].id, rating },
    ];
    setReviews(newReviews);

    // Save review to database
    try {
      await supabase.from("reviews").insert({
        user_id: userId,
        video_id: videos[currentIndex].id,
        rating,
        earning_amount: videos[currentIndex].earning_amount || 0,
      });

      // Update profile using the database function
      const { error: updateError } = await supabase.rpc("increment_reviews" as any, { 
        user_id_param: userId 
      });
      
      if (updateError) {
        console.error("Error updating profile:", updateError);
      }
    } catch (error) {
      console.error("Error saving review:", error);
      // Se houver erro, desbloquear botão
      setIsSubmitting(false);
      return;
    }

    if (currentIndex < videos.length - 1) {
      setCurrentIndex(currentIndex + 1);
      setRating(0);
      setHasWatched(false);
      // Desbloquear botão para próximo vídeo
      setIsSubmitting(false);
    } else {
      // Calculate total earnings and show completion modal
      const earnings = newReviews.reduce((sum, r) => {
        const video = videos.find((v) => v.id === r.video_id);
        return sum + (video?.earning_amount || 0);
      }, 0);
      setTotalEarnings(earnings);
      setShowCompletion(true);
      // Desbloquear botão
      setIsSubmitting(false);
    }
  };

  const completedCount = reviews.length;
  const pendingCount = 5 - completedCount;

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center space-y-4">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto"></div>
          <p className="text-muted-foreground">Loading videos...</p>
        </div>
      </div>
    );
  }

  const currentVideo = videos[currentIndex];

  return (
    <div className="min-h-screen p-4 md:p-8">
      <div className="max-w-6xl mx-auto space-y-6">
        {/* Header */}
        <div className="text-center space-y-4">
          <div className="flex items-center justify-center gap-2">
            <Trophy className="w-8 h-8 text-yellow-500" />
            <h1 className="text-3xl font-bold">Daily Reviews</h1>
          </div>
          <p className="text-muted-foreground">
            Earn $5 for each completed review.
          </p>

          {/* Progress Indicator */}
          <div className="flex items-center justify-center gap-2">
            {[...Array(5)].map((_, i) => (
              <div
                key={i}
                className={`w-12 h-12 rounded-full border-2 flex items-center justify-center ${
                  i < completedCount
                    ? "border-primary bg-primary text-white"
                    : i === completedCount
                    ? "border-primary text-primary"
                    : "border-muted text-muted-foreground"
                }`}
              >
                {i < completedCount ? (
                  <CheckCircle2 className="w-6 h-6" />
                ) : (
                  i + 1
                )}
              </div>
            ))}
          </div>
          <div className="space-y-1">
            <p className="text-xl font-semibold">
              Review {currentIndex + 1} of 5
            </p>
            <p className="text-sm text-muted-foreground">
              {pendingCount} reviews remaining
            </p>
          </div>
        </div>

        <div className="grid md:grid-cols-[2fr,1fr] gap-6">
          {/* Video Player */}
          <Card className="p-6 space-y-4">
            <div>
              <h3 className="text-xl font-semibold mb-4">
                {currentVideo?.title}
              </h3>
              
              {currentVideo?.youtube_url ? (
                <SimpleYouTubePlayer
                  videoUrl={currentVideo.youtube_url}
                  requiredWatchTime={30}
                  onWatchComplete={handleWatchComplete}
                  isCompleted={reviews.some((r) => r.video_id === currentVideo.id)}
                />
              ) : (
                <div className="aspect-video bg-black rounded-lg overflow-hidden relative group">
                  {currentVideo?.thumbnail_url && (
                    <img
                      src={currentVideo.thumbnail_url}
                      alt={currentVideo.title}
                      className="w-full h-full object-cover"
                    />
                  )}
                  <div className="absolute inset-0 flex items-center justify-center bg-black/50">
                    <p className="text-white text-center px-4">
                      Video unavailable
                    </p>
                  </div>
                </div>
              )}
            </div>

            <div className="space-y-4">
              <div className="space-y-2">
                <p className="text-sm font-medium">How do you rate this video?</p>
                <div className="flex gap-2">
                  {[1, 2, 3, 4, 5].map((star) => (
                    <button
                      key={star}
                      onClick={() => hasWatched && setRating(star)}
                      onMouseEnter={() => hasWatched && setHoverRating(star)}
                      onMouseLeave={() => setHoverRating(0)}
                      disabled={!hasWatched}
                      className="transition-transform hover:scale-110 disabled:cursor-not-allowed disabled:opacity-50"
                    >
                      <Star
                        className={`w-10 h-10 ${
                          star <= (hoverRating || rating)
                            ? "fill-yellow-500 text-yellow-500"
                            : "text-muted"
                        }`}
                      />
                    </button>
                  ))}
                </div>
              </div>

              <Button
                size="lg"
                className="w-full"
                onClick={handleRateAndNext}
                disabled={!hasWatched || rating === 0 || isSubmitting}
              >
                {isSubmitting ? "Processing..." : "Rate & Next"}
              </Button>
            </div>
          </Card>

          {/* Session Summary */}
          <div className="space-y-4">
            <Card className="p-6 space-y-4">
              <h3 className="font-semibold text-lg">Session Summary</h3>

              <div className="grid grid-cols-2 gap-4">
                <div className="text-center p-4 bg-success/10 rounded-lg">
                  <CheckCircle2 className="w-6 h-6 text-success mx-auto mb-2" />
                  <div className="text-2xl font-bold">{completedCount}</div>
                  <div className="text-xs text-muted-foreground">Completed</div>
                  <div className="text-success font-semibold mt-1">
                    +${completedCount * 5}.00
                  </div>
                </div>

                <div className="text-center p-4 bg-orange-500/10 rounded-lg">
                  <Hourglass className="w-6 h-6 text-orange-500 mx-auto mb-2" />
                  <div className="text-2xl font-bold">{pendingCount}</div>
                  <div className="text-xs text-muted-foreground">Pending</div>
                  <div className="text-orange-500 font-semibold mt-1">
                    +${pendingCount * 5}.00
                  </div>
                </div>
              </div>

              <div className="pt-4 border-t border-border">
                <div className="text-sm text-muted-foreground">
                  Total potential today
                </div>
                <div className="text-2xl font-bold text-success">$25.00</div>
              </div>
            </Card>

            {/* Video List */}
            <Card className="p-6 space-y-3">
              <h3 className="font-semibold">Today's Videos</h3>
              <div className="space-y-2">
                {videos.map((video, index) => {
                  const isCompleted = reviews.some((r) => r.video_id === video.id);
                  const isCurrent = index === currentIndex;

                  return (
                    <div
                      key={video.id}
                      className={`flex items-center gap-3 p-3 rounded-lg ${
                        isCurrent ? "bg-primary/10 border border-primary" : "bg-muted/50"
                      }`}
                    >
                      {isCompleted ? (
                        <CheckCircle2 className="w-5 h-5 text-success" />
                      ) : (
                        <div className="w-5 h-5 rounded-full border-2 border-muted-foreground" />
                      )}
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium truncate">
                          {video.title}
                        </p>
                        <p className="text-xs text-muted-foreground">
                          {isCompleted ? "Reviewed" : isCurrent ? "Reviewing" : "Pending"}
                        </p>
                      </div>
                    </div>
                  );
                })}
              </div>
            </Card>
          </div>
        </div>
      </div>

      <CompletionModal
        open={showCompletion}
        onOpenChange={setShowCompletion}
        earnings={totalEarnings}
        onContinue={() => navigate("/dashboard")}
      />
    </div>
  );
};

export default Review;
