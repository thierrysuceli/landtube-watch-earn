import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { PartyPopper } from "lucide-react";

interface CompletionModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  earnings: number;
  onContinue: () => void;
}

export const CompletionModal = ({
  open,
  onOpenChange,
  earnings,
  onContinue,
}: CompletionModalProps) => {
  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat("pt-BR", {
      style: "currency",
      currency: "USD",
    }).format(value);
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md text-center">
        <DialogHeader>
          <div className="flex justify-center mb-4">
            <PartyPopper className="w-16 h-16 text-success" />
          </div>
          <DialogTitle className="text-2xl">Congratulations!</DialogTitle>
          <DialogDescription className="text-lg">
            You've completed your daily reviews!
          </DialogDescription>
        </DialogHeader>
        <div className="space-y-6 py-4">
          <div className="space-y-2">
            <p className="text-muted-foreground">Session Earnings</p>
            <p className="text-4xl font-bold text-success">
              {formatCurrency(earnings)}
            </p>
          </div>
          <Button size="lg" className="w-full" onClick={onContinue}>
            Back to Dashboard
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
};
