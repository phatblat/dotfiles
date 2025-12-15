# ML Executor

Execute machine learning operations with structured output for model training, evaluation, and inference.

## Capability

This skill executes machine learning framework operations across TensorFlow, PyTorch, scikit-learn, and Keras. It returns structured results with metrics, predictions, and execution metadata.

## Supported Operations

### Model Training
- **train** - Train ML models with specified configuration
- **fine-tune** - Fine-tune pre-trained models
- **resume** - Resume training from checkpoint

### Model Evaluation
- **evaluate** - Evaluate model on test/validation data
- **predict** - Run inference on new data
- **benchmark** - Measure inference performance

### Data Operations
- **preprocess** - Apply preprocessing transformations
- **split** - Split data into train/val/test sets
- **augment** - Apply data augmentation

### Model Management
- **save** - Export model to disk
- **load** - Load model from disk
- **convert** - Convert model format (ONNX, TFLite, etc.)

### Hyperparameter Tuning
- **grid-search** - Grid search over hyperparameters
- **random-search** - Random search over hyperparameters
- **bayesian-optimize** - Bayesian optimization

## Supported Frameworks

- **TensorFlow/Keras** - Deep learning (TF 2.x)
- **PyTorch** - Deep learning
- **scikit-learn** - Traditional ML algorithms
- **XGBoost** - Gradient boosting
- **LightGBM** - Gradient boosting
- **auto** - Auto-detect from model file/script

## Usage Protocol

Agents invoke this skill by specifying operation parameters:

```json
{
  "action": "train",
  "framework": "pytorch",
  "config": {
    "modelScript": "train_model.py",
    "dataPath": "data/train.csv",
    "epochs": 50,
    "batchSize": 32,
    "learningRate": 0.001,
    "validationSplit": 0.2
  },
  "outputDir": "models/run1",
  "gpuEnabled": true
}
```

### Parameters

- **action** (required): Operation to execute
- **framework** (required): ML framework to use
- **config** (required): Operation-specific configuration
- **outputDir** (optional): Directory for outputs (models, logs)
- **gpuEnabled** (optional): Use GPU acceleration (default: auto-detect)
- **timeout** (optional): Timeout in seconds (default: 3600s)

## Training Configuration

### PyTorch Training
```json
{
  "action": "train",
  "framework": "pytorch",
  "config": {
    "modelScript": "model.py",
    "modelClass": "ResNet50",
    "dataPath": "data/",
    "epochs": 100,
    "batchSize": 64,
    "learningRate": 0.001,
    "optimizer": "adam",
    "lossFunction": "cross_entropy",
    "scheduler": "cosine_annealing",
    "checkpoint": true,
    "checkpointInterval": 10,
    "validationSplit": 0.2,
    "earlyStopping": {"patience": 10, "metric": "val_loss"}
  },
  "outputDir": "models/resnet50_run1",
  "gpuEnabled": true
}
```

### TensorFlow/Keras Training
```json
{
  "action": "train",
  "framework": "tensorflow",
  "config": {
    "modelScript": "model.py",
    "compiledModel": "model.h5",
    "dataPath": "data/train.tfrecord",
    "epochs": 50,
    "batchSize": 32,
    "validationData": "data/val.tfrecord",
    "callbacks": ["tensorboard", "model_checkpoint", "early_stopping"],
    "metrics": ["accuracy", "precision", "recall"]
  },
  "outputDir": "models/keras_run1",
  "gpuEnabled": true
}
```

### Scikit-learn Training
```json
{
  "action": "train",
  "framework": "sklearn",
  "config": {
    "algorithm": "RandomForestClassifier",
    "dataPath": "data/train.csv",
    "targetColumn": "label",
    "featureColumns": ["feature1", "feature2", "feature3"],
    "hyperparameters": {
      "n_estimators": 100,
      "max_depth": 10,
      "min_samples_split": 2
    },
    "crossValidation": {"folds": 5, "stratified": true},
    "featureScaling": "standard"
  },
  "outputDir": "models/rf_run1"
}
```

## Evaluation Configuration

### Model Evaluation
```json
{
  "action": "evaluate",
  "framework": "pytorch",
  "config": {
    "modelPath": "models/resnet50_run1/best_model.pt",
    "dataPath": "data/test/",
    "batchSize": 64,
    "metrics": ["accuracy", "precision", "recall", "f1", "confusion_matrix"]
  },
  "gpuEnabled": true
}
```

### Inference/Prediction
```json
{
  "action": "predict",
  "framework": "tensorflow",
  "config": {
    "modelPath": "models/keras_run1/saved_model",
    "inputData": "data/new_samples.csv",
    "batchSize": 32,
    "outputFormat": "probabilities"
  },
  "outputDir": "predictions/",
  "gpuEnabled": true
}
```

## Output Format

Returns structured JSON execution report:

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:30:00Z",
    "action": "train",
    "framework": "pytorch",
    "exitCode": 0,
    "duration": "1h 23m 45s",
    "status": "success",
    "gpuUsed": true,
    "outputDir": "models/resnet50_run1",
    "metadata": {
      "epochs": 100,
      "finalEpoch": 100,
      "bestEpoch": 87,
      "trainingTime": "1h 20m 12s",
      "samplesProcessed": 50000,
      "modelSize": "98.2MB"
    },
    "metrics": {
      "train_loss": 0.0234,
      "train_accuracy": 0.9876,
      "val_loss": 0.0312,
      "val_accuracy": 0.9823
    },
    "artifacts": {
      "bestModel": "models/resnet50_run1/best_model.pt",
      "lastModel": "models/resnet50_run1/last_model.pt",
      "trainingLog": "models/resnet50_run1/training.log",
      "metricsPlot": "models/resnet50_run1/metrics.png"
    }
  }
}
```

### Training Results (PyTorch)

```json
{
  "executionReport": {
    "action": "train",
    "framework": "pytorch",
    "exitCode": 0,
    "duration": "2h 15m 30s",
    "status": "success",
    "gpuUsed": true,
    "gpuModel": "NVIDIA RTX 4090",
    "metadata": {
      "epochs": 100,
      "finalEpoch": 100,
      "bestEpoch": 87,
      "earlyStopped": false,
      "trainingTime": "2h 10m 45s",
      "samplesProcessed": 100000,
      "batchSize": 64,
      "modelParameters": 25557032,
      "modelSize": "98.2MB",
      "peakGPUMemory": "8.3GB"
    },
    "metrics": {
      "train": {
        "loss": [0.6234, 0.3456, 0.1234, "...", 0.0234],
        "accuracy": [0.7123, 0.8456, 0.9234, "...", 0.9876],
        "finalLoss": 0.0234,
        "finalAccuracy": 0.9876
      },
      "validation": {
        "loss": [0.6543, 0.3678, 0.1456, "...", 0.0312],
        "accuracy": [0.6987, 0.8234, 0.9123, "...", 0.9823],
        "finalLoss": 0.0312,
        "finalAccuracy": 0.9823,
        "bestLoss": 0.0287,
        "bestAccuracy": 0.9845
      }
    },
    "artifacts": {
      "bestModel": "models/resnet50_run1/best_model.pt",
      "lastModel": "models/resnet50_run1/last_model.pt",
      "optimizer": "models/resnet50_run1/optimizer.pt",
      "trainingLog": "models/resnet50_run1/training.log",
      "metricsCSV": "models/resnet50_run1/metrics.csv",
      "lossPlot": "models/resnet50_run1/loss.png",
      "accuracyPlot": "models/resnet50_run1/accuracy.png"
    }
  }
}
```

### Evaluation Results

```json
{
  "executionReport": {
    "action": "evaluate",
    "framework": "pytorch",
    "exitCode": 0,
    "duration": "5m 23s",
    "status": "success",
    "gpuUsed": true,
    "metadata": {
      "samplesEvaluated": 10000,
      "batchSize": 64,
      "inferenceTime": "5m 18s",
      "avgInferenceTimePerSample": "31.8ms"
    },
    "metrics": {
      "accuracy": 0.9823,
      "precision": 0.9834,
      "recall": 0.9812,
      "f1Score": 0.9823,
      "confusionMatrix": [[1234, 23], [45, 8698]],
      "classificationReport": {
        "class_0": {"precision": 0.9651, "recall": 0.9815, "f1": 0.9732},
        "class_1": {"precision": 0.9974, "recall": 0.9948, "f1": 0.9961}
      }
    },
    "artifacts": {
      "predictionsCSV": "predictions/test_predictions.csv",
      "confusionMatrixPlot": "predictions/confusion_matrix.png",
      "rocCurve": "predictions/roc_curve.png"
    }
  }
}
```

### Prediction Results

```json
{
  "executionReport": {
    "action": "predict",
    "framework": "tensorflow",
    "exitCode": 0,
    "duration": "2m 45s",
    "status": "success",
    "gpuUsed": true,
    "metadata": {
      "samplesProcessed": 5000,
      "batchSize": 32,
      "inferenceTime": "2m 40s",
      "avgInferenceTimePerSample": "32ms"
    },
    "predictions": {
      "format": "probabilities",
      "shape": [5000, 10],
      "outputFile": "predictions/predictions.csv",
      "samplePredictions": [
        {"sample_id": 0, "predicted_class": 7, "confidence": 0.9876, "probabilities": [0.001, 0.002, "..."]},
        {"sample_id": 1, "predicted_class": 3, "confidence": 0.8234, "probabilities": [0.012, 0.034, "..."]}
      ]
    },
    "artifacts": {
      "predictionsCSV": "predictions/predictions.csv",
      "predictionsJSON": "predictions/predictions.json"
    }
  }
}
```

### Scikit-learn Cross-Validation

```json
{
  "executionReport": {
    "action": "train",
    "framework": "sklearn",
    "exitCode": 0,
    "duration": "3m 12s",
    "status": "success",
    "metadata": {
      "algorithm": "RandomForestClassifier",
      "samplesProcessed": 10000,
      "features": 20,
      "crossValidationFolds": 5,
      "modelSize": "45.3MB"
    },
    "metrics": {
      "crossValidation": {
        "accuracy": [0.9234, 0.9345, 0.9289, 0.9312, 0.9267],
        "meanAccuracy": 0.9289,
        "stdAccuracy": 0.0042,
        "f1Score": [0.9123, 0.9234, 0.9178, 0.9201, 0.9156],
        "meanF1": 0.9178,
        "stdF1": 0.0044
      },
      "finalModel": {
        "trainAccuracy": 0.9987,
        "testAccuracy": 0.9312
      }
    },
    "artifacts": {
      "model": "models/rf_run1/model.pkl",
      "scaler": "models/rf_run1/scaler.pkl",
      "featureImportances": "models/rf_run1/feature_importances.csv",
      "metricsPlot": "models/rf_run1/cv_metrics.png"
    }
  }
}
```

## Hyperparameter Tuning

### Grid Search
```json
{
  "action": "grid-search",
  "framework": "sklearn",
  "config": {
    "algorithm": "SVC",
    "dataPath": "data/train.csv",
    "targetColumn": "label",
    "paramGrid": {
      "C": [0.1, 1, 10, 100],
      "kernel": ["linear", "rbf"],
      "gamma": ["scale", "auto", 0.001, 0.01]
    },
    "scoring": "f1_weighted",
    "crossValidation": {"folds": 5}
  },
  "outputDir": "models/svc_gridsearch"
}
```

### Results
```json
{
  "executionReport": {
    "action": "grid-search",
    "framework": "sklearn",
    "exitCode": 0,
    "duration": "15m 32s",
    "status": "success",
    "metadata": {
      "totalCombinations": 32,
      "bestParams": {"C": 10, "kernel": "rbf", "gamma": 0.01},
      "bestScore": 0.9567
    },
    "results": {
      "allScores": [
        {"params": {"C": 0.1, "kernel": "linear", "gamma": "scale"}, "meanScore": 0.8234, "stdScore": 0.0123},
        {"params": {"C": 10, "kernel": "rbf", "gamma": 0.01}, "meanScore": 0.9567, "stdScore": 0.0089}
      ],
      "bestParams": {"C": 10, "kernel": "rbf", "gamma": 0.01},
      "bestScore": 0.9567
    },
    "artifacts": {
      "bestModel": "models/svc_gridsearch/best_model.pkl",
      "searchResults": "models/svc_gridsearch/grid_search_results.csv"
    }
  }
}
```

## Data Preprocessing

### Preprocessing Operations
```json
{
  "action": "preprocess",
  "framework": "sklearn",
  "config": {
    "inputData": "data/raw.csv",
    "operations": [
      {"type": "fillna", "strategy": "mean", "columns": ["feature1", "feature2"]},
      {"type": "scale", "method": "standard", "columns": ["feature1", "feature2", "feature3"]},
      {"type": "encode", "method": "onehot", "columns": ["category1", "category2"]},
      {"type": "pca", "nComponents": 10, "columns": ["feature1", "feature2", "feature3"]}
    ],
    "outputPath": "data/preprocessed.csv",
    "saveTransformers": true
  },
  "outputDir": "data/transformers/"
}
```

## Platform & Environment

### GPU Detection
- Auto-detects CUDA/ROCm availability
- Reports GPU model and memory
- Falls back to CPU if GPU unavailable

### Framework Installation Check
- Verifies framework is installed
- Reports version information
- Suggests installation command if missing

### Virtual Environment Support
- Detects conda/venv environments
- Can activate specified environment
- Reports Python version and packages

## Tool Requirements

### Core Frameworks (install as needed)
- **PyTorch**: `pip install torch torchvision`
- **TensorFlow**: `pip install tensorflow`
- **scikit-learn**: `pip install scikit-learn`
- **XGBoost**: `pip install xgboost`
- **LightGBM**: `pip install lightgbm`

### Optional Dependencies
- **CUDA**: For GPU acceleration (PyTorch/TensorFlow)
- **tensorboard**: Training visualization
- **matplotlib/seaborn**: Plotting metrics
- **pandas**: Data loading and preprocessing
- **numpy**: Numerical operations

## Constraints

This skill does NOT:
- Design model architectures (calling agent decides)
- Select algorithms or hyperparameters (calling agent decides)
- Interpret model results or provide insights
- Recommend improvements to models
- Debug model performance issues
- Explain ML concepts or algorithms
- Collect or generate training data
- Deploy models to production
- Monitor deployed models
- Perform feature engineering (beyond basic preprocessing)
- Make decisions about train/test splits
- Choose evaluation metrics

## Error Handling

Returns structured error information for:

- **Framework not found**: PyTorch/TensorFlow not installed
- **CUDA error**: GPU issues or out of memory
- **Data loading error**: Invalid data path or format
- **Model loading error**: Invalid model file or incompatible version
- **Training failure**: Model divergence, NaN losses
- **Out of memory**: Insufficient RAM/VRAM
- **Timeout exceeded**: Training took too long
- **Invalid configuration**: Missing required parameters

Example error response:

```json
{
  "error": {
    "type": "cuda-out-of-memory",
    "message": "CUDA out of memory. Tried to allocate 2.5 GB",
    "exitCode": 1,
    "stderr": "RuntimeError: CUDA out of memory...",
    "metadata": {
      "gpuModel": "NVIDIA RTX 3080",
      "gpuMemoryTotal": "10GB",
      "gpuMemoryAllocated": "8.5GB",
      "batchSize": 128,
      "modelParameters": 45000000
    },
    "solution": "Reduce batch size (currently 128) or model size. Try batchSize: 64"
  }
}
```

### Framework Not Found

```json
{
  "error": {
    "type": "framework-not-found",
    "message": "PyTorch not found in Python environment",
    "exitCode": 127,
    "stderr": "ModuleNotFoundError: No module named 'torch'",
    "solution": "Install PyTorch: pip install torch torchvision or conda install pytorch torchvision -c pytorch"
  }
}
```

### Training Diverged

```json
{
  "error": {
    "type": "training-diverged",
    "message": "Training loss became NaN at epoch 15",
    "exitCode": 1,
    "metadata": {
      "epoch": 15,
      "lastValidLoss": 0.3456,
      "learningRate": 0.01
    },
    "solution": "Reduce learning rate (try 0.001) or add gradient clipping"
  }
}
```

### Data Loading Error

```json
{
  "error": {
    "type": "data-loading-error",
    "message": "Failed to load training data",
    "exitCode": 1,
    "stderr": "FileNotFoundError: data/train.csv not found",
    "solution": "Verify data path exists and is accessible"
  }
}
```

## Performance Optimization

### GPU Utilization
- Automatic mixed precision (AMP) support
- Multi-GPU training with DataParallel/DistributedDataParallel
- Gradient accumulation for large batch sizes
- Reports GPU utilization and memory usage

### Memory Management
- Automatic batch size adjustment on OOM
- Gradient checkpointing for large models
- Memory-efficient data loading with prefetching

### Monitoring
- Real-time training metrics via stdout
- TensorBoard integration for visualization
- Progress bars for long-running operations
- Estimated time remaining

## Common ML Workflows

### Train Image Classification Model (PyTorch)
```json
{
  "action": "train",
  "framework": "pytorch",
  "config": {
    "modelScript": "train_resnet.py",
    "modelClass": "ResNet50",
    "dataPath": "data/imagenet/",
    "epochs": 100,
    "batchSize": 256,
    "learningRate": 0.1,
    "optimizer": "sgd",
    "momentum": 0.9,
    "weightDecay": 0.0001,
    "scheduler": "step_lr",
    "validationSplit": 0.1,
    "checkpointInterval": 5
  },
  "outputDir": "models/resnet50_imagenet",
  "gpuEnabled": true
}
```

### Train Tabular Model (Scikit-learn)
```json
{
  "action": "train",
  "framework": "sklearn",
  "config": {
    "algorithm": "XGBClassifier",
    "dataPath": "data/customers.csv",
    "targetColumn": "churn",
    "hyperparameters": {
      "n_estimators": 200,
      "max_depth": 6,
      "learning_rate": 0.1
    },
    "crossValidation": {"folds": 10}
  },
  "outputDir": "models/churn_prediction"
}
```

### Fine-tune Pre-trained Model
```json
{
  "action": "fine-tune",
  "framework": "pytorch",
  "config": {
    "pretrainedModel": "models/bert-base-uncased",
    "dataPath": "data/sentiment_analysis/",
    "epochs": 10,
    "batchSize": 16,
    "learningRate": 2e-5,
    "freezeLayers": ["embeddings", "encoder.layer.0-8"]
  },
  "outputDir": "models/bert_sentiment",
  "gpuEnabled": true
}
```
