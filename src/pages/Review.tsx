import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Star, CheckCircle2, Hourglass, Trophy, Play } from "lucide-react";
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

interface DailyList {
  list_id: string;
  video_ids: string[];
  current_video_index: number;
  videos_completed: number;
  is_completed: boolean;
  list_date: string;
}

const Review = () => {
  const navigate = useNavigate();
  const [videos, setVideos] = useState<Video[]>([]);
  const [dailyList, setDailyList] = useState<DailyList | null>(null);
  const [currentIndex, setCurrentIndex] = useState(0);
  const [rating, setRating] = useState(0);
  const [hoverRating, setHoverRating] = useState(0);
  const [hasWatched, setHasWatched] = useState(false);
  const [loading, setLoading] = useState(true);
  const [userId, setUserId] = useState<string>("");
  const [showCompletion, setShowCompletion] = useState(false);
  const [totalEarnings, setTotalEarnings] = useState(0);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [completedVideoIds, setCompletedVideoIds] = useState<Set<string>>(new Set());

  useEffect(() => {
    loadDailyList();
  }, []);

  const loadDailyList = async () => {
    try {
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) {
        navigate("/auth");
        return;
      }

      setUserId(session.user.id);

      // Call the database function to get or create today's list
      const { data, error } = await supabase.rpc("get_or_create_daily_list", {
        user_id_param: session.user.id,
      });

      if (error) {
        // Check if it's because user already completed today
        if (error.message.includes("Not enough available videos")) {
          toast.info("No more videos available for review!");
          navigate("/dashboard");
          return;
        }
        throw error;
      }

      if (!data || data.length === 0) {
        toast.error("Failed to load daily list");
        navigate("/dashboard");
        return;
      }

      const listData = data[0] as DailyList;
      
      // Check if list is already completed
      if (listData.is_completed) {
        toast.info("You've already completed your daily reviews!");
        navigate("/dashboard");
        return;
      }

      setDailyList(listData);

      // Fetch video details for the list
      const { data: videoData, error: videoError } = await supabase
        .from("videos")
        .select("*")
        .in("id", listData.video_ids);

      if (videoError) throw videoError;

      // Sort videos in the same order as video_ids array
      const sortedVideos = listData.video_ids
        .map((id) => videoData?.find((v) => v.id === id))
        .filter((v): v is Video => v !== undefined);

      setVideos(sortedVideos);

      // Set current index from list
      setCurrentIndex(listData.current_video_index);

      // Get already completed videos in this list
      const { data: reviewsData } = await supabase
        .from("reviews")
        .select("video_id")
        .eq("user_id", session.user.id)
        .in("video_id", listData.video_ids);

      if (reviewsData) {
        setCompletedVideoIds(new Set(reviewsData.map((r) => r.video_id)));
      }

      // Show message if continuing from previous session
      if (listData.videos_completed > 0) {
        toast.success(
          `Continue reviewing! ${listData.videos_completed}/5 videos completed`,
          { duration: 4000 }
        );
      }
    } catch (error) {
      console.error("Error loading daily list:", error);
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
    if (isSubmitting) return;

    if (rating === 0) {
      toast.error("Please select a rating");
      return;
    }

    if (!dailyList) {
      toast.error("List data not found");
      return;
    }

    setIsSubmitting(true);

    const currentVideo = videos[currentIndex];

    try {
      // Save review to database
      const { error: reviewError } = await supabase.from("reviews").insert({
        user_id: userId,
        video_id: currentVideo.id,
        rating,
        earning_amount: currentVideo.earning_amount || 0,
      });

      if (reviewError) throw reviewError;

      // Update completed video IDs
      const newCompletedIds = new Set(completedVideoIds);
      newCompletedIds.add(currentVideo.id);
      setCompletedVideoIds(newCompletedIds);

      // Update list progress in database
      const { error: progressError } = await supabase.rpc("update_list_progress", {
        user_id_param: userId,
        video_index_param: currentIndex,
      });

      if (progressError) throw progressError;

      // Check if this was the last video
      const newCompletedCount = newCompletedIds.size;
      const isListComplete = newCompletedCount >= 5;

      if (isListComplete) {
        // Calculate total earnings from all 5 videos (for display only)
        const earnings = videos.reduce((sum, video) => sum + (video.earning_amount || 0), 0);
        setTotalEarnings(earnings);
        
        // Balance is already updated by increment_reviews function in update_list_progress
        // No need to update it here to avoid duplication

        toast.success(`List completed! You earned $${earnings.toFixed(2)}!`);
        setShowCompletion(true);
      } else {
        // Move to next video
        const nextIndex = currentIndex + 1;
        setCurrentIndex(nextIndex);
        setRating(0);
        setHasWatched(false);
        toast.success("Review saved! Moving to next video...");
      }
    } catch (error) {
      console.error("Error saving review:", error);
      toast.error("Failed to save review. Please try again.");
    } finally {
      setIsSubmitting(false);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center space-y-4">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto"></div>
          <p className="text-muted-foreground">Loading your daily list...</p>
        </div>
      </div>
    );
  }

  if (!dailyList || videos.length === 0) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <Card className="p-8 max-w-md text-center space-y-4">
          <Trophy className="w-16 h-16 text-yellow-500 mx-auto" />
          <h2 className="text-2xl font-bold">No Videos Available</h2>
          <p className="text-muted-foreground">
            There are no videos available for review at the moment.
          </p>
          <Button onClick={() => navigate("/dashboard")}>
            Back to Dashboard
          </Button>
        </Card>
      </div>
    );
  }

  const currentVideo = videos[currentIndex];
  const completedCount = completedVideoIds.size;
  const pendingCount = 5 - completedCount;

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
            Complete all 5 videos to earn your daily reward!
          </p>

          {/* Progress Indicator */}
          <div className="flex items-center justify-center gap-2">
            {[...Array(5)].map((_, i) => {
              const videoId = dailyList.video_ids[i];
              const isCompleted = completedVideoIds.has(videoId);
              const isCurrent = i === currentIndex;

              return (
                <div
                  key={i}
                  className={`w-12 h-12 rounded-full border-2 flex items-center justify-center transition-all ${
                    isCompleted
                      ? "border-green-500 bg-green-500 text-white"
                      : isCurrent
                      ? "border-primary bg-primary/10 text-primary scale-110"
                      : "border-muted text-muted-foreground"
                  }`}
                >
                  {isCompleted ? (
                    <CheckCircle2 className="w-6 h-6" />
                  ) : isCurrent ? (
                    <Play className="w-5 h-5" />
                  ) : (
                    i + 1
                  )}
                </div>
              );
            })}
          </div>
          <div className="space-y-1">
            <p className="text-xl font-semibold">
              Video {currentIndex + 1} of 5
            </p>
            <p className="text-sm text-muted-foreground">
              {completedCount} completed • {pendingCount} remaining
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
                  isCompleted={completedVideoIds.has(currentVideo.id)}
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
                {isSubmitting
                  ? "Saving..."
                  : currentIndex === 4
                  ? "Complete & Earn"
                  : "Rate & Next"}
              </Button>
            </div>
          </Card>

          {/* Session Summary */}
          <div className="space-y-4">
            <Card className="p-6 space-y-4">
              <h3 className="font-semibold text-lg">List Progress</h3>

              <div className="grid grid-cols-2 gap-4">
                <div className="text-center p-4 bg-green-500/10 rounded-lg">
                  <CheckCircle2 className="w-6 h-6 text-green-500 mx-auto mb-2" />
                  <div className="text-2xl font-bold">{completedCount}</div>
                  <div className="text-xs text-muted-foreground">Completed</div>
                </div>

                <div className="text-center p-4 bg-orange-500/10 rounded-lg">
                  <Hourglass className="w-6 h-6 text-orange-500 mx-auto mb-2" />
                  <div className="text-2xl font-bold">{pendingCount}</div>
                  <div className="text-xs text-muted-foreground">Remaining</div>
                </div>
              </div>

              <div className="pt-4 border-t border-border">
                <div className="text-sm text-muted-foreground mb-1">
                  Complete all videos to earn
                </div>
                <div className="text-2xl font-bold text-green-500">
                  ${videos.reduce((sum, v) => sum + (v.earning_amount || 0), 0).toFixed(2)}
                </div>
                <p className="text-xs text-muted-foreground mt-2">
                  💡 Earnings are credited after completing the entire list
                </p>
              </div>
            </Card>

            {/* Video List */}
            <Card className="p-6 space-y-3">
              <h3 className="font-semibold">Today's Videos</h3>
              <div className="space-y-2">
                {videos.map((video, index) => {
                  const isCompleted = completedVideoIds.has(video.id);
                  const isCurrent = index === currentIndex;

                  return (
                    <div
                      key={video.id}
                      className={`flex items-center gap-3 p-3 rounded-lg transition-all ${
                        isCurrent
                          ? "bg-primary/10 border border-primary"
                          : "bg-muted/50"
                      }`}
                    >
                      {isCompleted ? (
                        <CheckCircle2 className="w-5 h-5 text-green-500" />
                      ) : isCurrent ? (
                        <Play className="w-5 h-5 text-primary" />
                      ) : (
                        <div className="w-5 h-5 rounded-full border-2 border-muted-foreground" />
                      )}
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium truncate">
                          {video.title}
                        </p>
                        <p className="text-xs text-muted-foreground">
                          ${(video.earning_amount || 0).toFixed(2)} •{" "}
                          {isCompleted
                            ? "✓ Reviewed"
                            : isCurrent
                            ? "▶ Watching"
                            : "⏳ Pending"}
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
