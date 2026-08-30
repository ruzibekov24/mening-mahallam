/**
 * Dependency-free inline SVG line chart for small stat-trend previews.
 * Renders a simple polyline — no axes, ticks, or legends.
 */

export type SparklinePoint = { x: number; y: number };

const WIDTH = 160;
const HEIGHT = 36;
const PADDING = 3;

function toPoints(data: SparklinePoint[] | number[]): SparklinePoint[] {
  if (data.length === 0) return [];
  if (typeof data[0] === 'number') {
    return (data as number[]).map((y, x) => ({ x, y }));
  }
  return data as SparklinePoint[];
}

/**
 * Renders a minimal SVG sparkline. Returns an empty string if there
 * isn't enough data to draw a meaningful trend line (caller should
 * show a fallback message in that case).
 */
export function renderSparkline(data: SparklinePoint[] | number[]): string {
  const points = toPoints(data);
  if (points.length < 2) return '';

  const xs = points.map((p) => p.x);
  const ys = points.map((p) => p.y);
  const minX = Math.min(...xs);
  const maxX = Math.max(...xs);
  const minY = Math.min(...ys);
  const maxY = Math.max(...ys);

  const spanX = maxX - minX || 1;
  const spanY = maxY - minY || 1;

  const scaled = points.map((p) => {
    const nx = PADDING + ((p.x - minX) / spanX) * (WIDTH - PADDING * 2);
    const ny =
      HEIGHT -
      PADDING -
      ((p.y - minY) / spanY) * (HEIGHT - PADDING * 2);
    return `${nx.toFixed(1)},${ny.toFixed(1)}`;
  });

  return `
    <svg class="sparkline" viewBox="0 0 ${WIDTH} ${HEIGHT}" width="${WIDTH}" height="${HEIGHT}" preserveAspectRatio="none" aria-hidden="true">
      <polyline points="${scaled.join(' ')}" fill="none" stroke="var(--blue)" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
    </svg>
  `;
}
