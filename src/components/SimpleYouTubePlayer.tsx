import { useState, useEffect, useRef } from "react";
import { Progress } from "@/components/ui/progress";
import { AlertCircle, Play, CheckCircle2, Clock } from "lucide-react";
import { Alert, AlertDescription } from "@/components/ui/alert";

interface SimpleYouTubePlayerProps {
  videoUrl: string;
  requiredWatchTime: number; // Tempo em segundos (ex: 30)
  onWatchComplete: () => void;
  isCompleted: boolean;
}

export const SimpleYouTubePlayer = ({
  videoUrl,
  requiredWatchTime = 30,
  onWatchComplete,
  isCompleted,
}: SimpleYouTubePlayerProps) => {
  const [timeWatched, setTimeWatched] = useState(0);
  const [isTimerActive, setIsTimerActive] = useState(false);
  const [canComplete, setCanComplete] = useState(false);
  const iframeRef = useRef<HTMLIFrameElement>(null);

  // Resetar estados quando mudar de vídeo
  useEffect(() => {
    setTimeWatched(0);
    setIsTimerActive(false);
    setCanComplete(false);
  }, [videoUrl]);

  // Extrair ID do vídeo do YouTube
  const getVideoId = (url: string): string | null => {
    const regExp = /^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#&?]*).*/;
    const match = url.match(regExp);
    return match && match[7].length === 11 ? match[7] : null;
  };

  const videoId = getVideoId(videoUrl);
  const progress = (timeWatched / requiredWatchTime) * 100;
  const timeRemaining = Math.max(0, requiredWatchTime - timeWatched);

  // Timer que conta os segundos (NÃO para o vídeo)
  useEffect(() => {
    let interval: NodeJS.Timeout;

    if (isTimerActive && timeWatched < requiredWatchTime) {
      interval = setInterval(() => {
        setTimeWatched((prev) => {
          const newTime = prev + 1;
          
          // Quando atingir o tempo necessário - apenas marca como completo
          if (newTime >= requiredWatchTime && !canComplete) {
            setCanComplete(true);
            // NÃO para o timer - apenas marca como completo
            onWatchComplete();
          }
          
          return newTime;
        });
      }, 1000);
    }

    return () => {
      if (interval) clearInterval(interval);
    };
  }, [isTimerActive, timeWatched, requiredWatchTime, canComplete, onWatchComplete]);

  // Iniciar timer quando usuário clicar em "Começar a assistir"
  const handleStartWatching = () => {
    setIsTimerActive(true);
  };

  // Formatar tempo em MM:SS
  const formatTime = (seconds: number): string => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  if (!videoId) {
    return (
      <Alert variant="destructive">
        <AlertCircle className="h-4 w-4" />
        <AlertDescription>
          Invalid video URL. Please use a valid YouTube link.
        </AlertDescription>
      </Alert>
    );
  }

  return (
    <div className="space-y-4">
      {/* Player do YouTube - Controles bloqueados nos primeiros 30s */}
      <div className="relative w-full aspect-video bg-black rounded-lg overflow-hidden group">
        <iframe
          ref={iframeRef}
          src={`https://www.youtube.com/embed/${videoId}?autoplay=${isTimerActive ? 1 : 0}&controls=1&rel=0&modestbranding=1&showinfo=0&fs=1&disablekb=0`}
          title="YouTube video player"
          allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; fullscreen"
          allowFullScreen
          className="absolute inset-0 w-full h-full"
        />
        
        {/* Overlay de bloqueio ANTES de iniciar */}
        {!isTimerActive && (
          <div className="absolute inset-0 bg-gradient-to-br from-black/80 via-gray-900/70 to-black/80 flex items-center justify-center z-20 pointer-events-auto">
            <button
              onClick={handleStartWatching}
              className="group/btn relative"
            >
              {/* Efeito de pulso de fundo - VERMELHO */}
              <div className="absolute inset-0 bg-gradient-to-r from-red-600 to-red-700 rounded-full blur-xl opacity-50 group-hover/btn:opacity-75 animate-pulse"></div>
              
              {/* Botão principal - VERMELHO/PRETO */}
              <div className="relative flex items-center justify-center w-20 h-20 bg-gradient-to-br from-red-600 via-red-700 to-gray-900 rounded-full shadow-2xl transform transition-all duration-300 group-hover/btn:scale-110 group-hover/btn:shadow-red-600/50">
                <Play className="h-10 w-10 text-white fill-white ml-1" />
              </div>
            </button>
          </div>
        )}
        
        {/* Overlay invisível para BLOQUEAR CONTROLES durante os primeiros 30s */}
        {isTimerActive && !canComplete && (
          <div className="absolute bottom-0 left-0 right-0 h-12 bg-transparent z-10 pointer-events-auto" 
               title="Watch for 30 seconds to unlock controls">
          </div>
        )}
      </div>

      {/* Controles e Timer */}
      <div className="space-y-3">
        {/* Timer Ativo - APENAS BARRA DE PROGRESSO (vermelho/cinza escuro) */}
        {isTimerActive && !canComplete && (
          <div className="bg-gradient-to-r from-gray-900 via-gray-800 to-gray-900 border border-red-900/30 rounded-lg p-3 shadow-lg">
            <Progress value={progress} className="h-3" />
          </div>
        )}

        {/* Vídeo Completo - tema VERDE */}
        {canComplete && (
          <Alert className="border-green-600 bg-gradient-to-r from-green-100 to-emerald-100 shadow-lg">
            <CheckCircle2 className="h-5 w-5 text-green-600" />
            <AlertDescription className="text-green-900">
              <div className="font-semibold mb-1">
                🎉 Congratulations! You can rate now!
              </div>
              <div className="text-sm">
                You've watched the required {requiredWatchTime} seconds. 
                Continue watching if you want, and rate when you're ready to earn <strong>$5.00</strong>!
              </div>
            </AlertDescription>
          </Alert>
        )}
      </div>
    </div>
  );
};
