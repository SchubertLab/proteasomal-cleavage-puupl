for i in {1..10}; do
    python -u src/puupl/run.py configs/config-cterm.yaml cv_current_fold:$i | \
        tee trained_models/logs/cterm-fold-$1.log
done
