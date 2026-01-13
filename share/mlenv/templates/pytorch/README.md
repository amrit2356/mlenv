# {{PROJECT_NAME}}

PyTorch Deep Learning Project

**Created:** {{DATE}}  
**Author:** {{AUTHOR}}

## Getting Started

### 1. Start MLEnv Container

```bash
mlenv up --requirements requirements.txt --port 8888:8888,6006:6006
```

### 2. Enter Container

```bash
mlenv exec
```

### 3. Run Training

```bash
python train.py
```

### 4. Monitor with TensorBoard

```bash
# In another terminal
mlenv exec -c "tensorboard --logdir runs --host 0.0.0.0"

# Open: http://localhost:6006
```

### 5. Jupyter Lab (Optional)

```bash
mlenv jupyter
# Follow the URL with token
```

## Project Structure

```
{{PROJECT_NAME}}/
├── train.py              # Training script
├── model.py              # Model definition
├── dataset.py            # Dataset loader
├── config.yaml           # Hyperparameters
├── requirements.txt      # Dependencies
├── notebooks/            # Jupyter notebooks
├── data/                 # Datasets
├── models/               # Saved models
└── runs/                 # TensorBoard logs
```

## Configuration

Edit `config.yaml` to adjust hyperparameters:

```yaml
model:
  name: resnet50
  pretrained: true

training:
  batch_size: 64
  epochs: 100
  learning_rate: 0.001
  
data:
  train_path: data/train
  val_path: data/val
```

## Tips

- Use `--gpu 0,1` to specify GPUs
- Increase `--memory 32g` for large datasets
- Enable mixed precision: `torch.cuda.amp` for faster training
- Save checkpoints regularly

## Resources

- [PyTorch Documentation](https://pytorch.org/docs/)
- [TensorBoard Guide](https://www.tensorflow.org/tensorboard)
- [MLEnv Documentation](https://github.com/your-username/mlenv)
