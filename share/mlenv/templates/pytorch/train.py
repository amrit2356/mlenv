#!/usr/bin/env python3
"""
{{PROJECT_NAME}} - Training Script
Generated: {{DATE}}
Author: {{AUTHOR}}
"""

import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader
from torch.utils.tensorboard import SummaryWriter
from tqdm import tqdm
import yaml

# Check GPU availability
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print(f"Using device: {device}")

# Load configuration
with open("config.yaml", "r") as f:
    config = yaml.safe_load(f)

# Initialize TensorBoard
writer = SummaryWriter("runs/experiment_1")

class SimpleModel(nn.Module):
    """Simple neural network model"""
    def __init__(self, input_size=784, hidden_size=256, num_classes=10):
        super().__init__()
        self.fc1 = nn.Linear(input_size, hidden_size)
        self.relu = nn.ReLU()
        self.fc2 = nn.Linear(hidden_size, num_classes)
    
    def forward(self, x):
        x = x.view(x.size(0), -1)
        x = self.fc1(x)
        x = self.relu(x)
        x = self.fc2(x)
        return x

def train_epoch(model, dataloader, criterion, optimizer, epoch):
    """Train for one epoch"""
    model.train()
    running_loss = 0.0
    correct = 0
    total = 0
    
    pbar = tqdm(dataloader, desc=f"Epoch {epoch}")
    for batch_idx, (inputs, targets) in enumerate(pbar):
        inputs, targets = inputs.to(device), targets.to(device)
        
        # Forward pass
        outputs = model(inputs)
        loss = criterion(outputs, targets)
        
        # Backward pass
        optimizer.zero_grad()
        loss.backward()
        optimizer.step()
        
        # Statistics
        running_loss += loss.item()
        _, predicted = outputs.max(1)
        total += targets.size(0)
        correct += predicted.eq(targets).sum().item()
        
        # Update progress bar
        pbar.set_postfix({
            'loss': f'{running_loss/(batch_idx+1):.3f}',
            'acc': f'{100.*correct/total:.2f}%'
        })
    
    epoch_loss = running_loss / len(dataloader)
    epoch_acc = 100. * correct / total
    
    return epoch_loss, epoch_acc

def main():
    """Main training loop"""
    print("=" * 50)
    print(f"Training {{PROJECT_NAME}}")
    print("=" * 50)
    
    # Load configuration
    batch_size = config['training']['batch_size']
    epochs = config['training']['epochs']
    lr = config['training']['learning_rate']
    
    # Create model
    model = SimpleModel().to(device)
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.Adam(model.parameters(), lr=lr)
    
    print(f"\nModel: {model.__class__.__name__}")
    print(f"Parameters: {sum(p.numel() for p in model.parameters()):,}")
    print(f"Device: {device}\n")
    
    # Training loop
    for epoch in range(1, epochs + 1):
        # TODO: Load your data here
        # train_loader = DataLoader(your_dataset, batch_size=batch_size, shuffle=True)
        
        # For demo purposes, we'll just print
        print(f"Epoch {epoch}/{epochs}")
        print("TODO: Implement data loading and training")
        
        # Example: train_loss, train_acc = train_epoch(model, train_loader, criterion, optimizer, epoch)
        
        # Log to TensorBoard
        # writer.add_scalar('Loss/train', train_loss, epoch)
        # writer.add_scalar('Accuracy/train', train_acc, epoch)
        
        # Save checkpoint
        if epoch % 10 == 0:
            checkpoint_path = f"models/checkpoint_epoch_{epoch}.pth"
            torch.save({
                'epoch': epoch,
                'model_state_dict': model.state_dict(),
                'optimizer_state_dict': optimizer.state_dict(),
            }, checkpoint_path)
            print(f"Saved checkpoint: {checkpoint_path}")
    
    writer.close()
    print("\nTraining complete!")

if __name__ == "__main__":
    main()
