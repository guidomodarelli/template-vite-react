import { SIDEBAR_ANIMATION_DURATION, useSidebar } from '@/components/ui/sidebar';
import * as echarts from 'echarts';
import { useEffect, useRef } from 'react';
import { Subject } from 'rxjs/internal/Subject';
import { debounceTime } from 'rxjs/operators';

interface EChartProps {
  option: echarts.EChartsOption;
}

export const EChart: React.FC<EChartProps> = (props) => {
  const { logger } = props;
  const { open } = useSidebar();
  const container = useRef<HTMLDivElement>(null);
  const chart = useRef<echarts.ECharts>(null);
  const resizeNotifier$ = useRef(new Subject<void>());

  useEffect(() => {
    chart.current = echarts.init(container.current, null, {
      renderer: 'canvas',
    });

    window.addEventListener('resize', emitResizeEvent);
    resizeNotifier$.current.pipe(debounceTime(SIDEBAR_ANIMATION_DURATION + 50)).subscribe({
      next: () => {
        chart.current?.resize();
      },
    });

    return () => {
      window.removeEventListener('resize', emitResizeEvent);
      resizeNotifier$.current.complete();
      chart.current?.dispose();
    };
  }, []);

  useEffect(() => {
    chart.current?.setOption(props.option);
  }, [props.option]);

  const emitResizeEvent = () => {
    resizeNotifier$.current.next();
  };

  useEffect(() => {
    emitResizeEvent();
  }, [open]);

  return <div className='h-[33vh] w-full relative overflow-hidden' ref={container} />;
};
