import { Injectable } from '@angular/core';

export const colorModes = {
  lightHighContrast: 'lightHighContrast',
  light: 'light',
  dark: 'dark',
};

@Injectable({ providedIn: 'root' })
export class ColorsService {
  public toHsl(value:string, colorMode?:string):string {
    return `hsl(${this.valueHash(value)}, 50%, ${colorMode === colorModes.lightHighContrast ? '30%' : '50%'})`;
  }

  public toHsla(value:string, opacity:number) {
    return `hsla(${this.valueHash(value)}, 50%, 30%, ${opacity}%)`;
  }

  protected valueHash(value:string) {
    let hash = 0;
    for (let i = 0; i < value.length; i++) {
      hash = value.charCodeAt(i) + ((hash << 5) - hash);
    }

    return hash % 360;
  }

  public colorMode():string {
    if (document.body.getAttribute('data-color-mode') === 'dark') {
      return colorModes.dark;
    }

    if (document.body.getAttribute('data-light-theme') === 'light_high_contrast') {
      return colorModes.lightHighContrast;
    }

    return colorModes.light;
  }

  public getContrastTextColor(hslColor:string):'white' | 'black' {
    const hslMatch = hslColor.match(/hsl\((\d+),\s*(\d+)%?,\s*(\d+)%?\)/);
    if (!hslMatch) return 'black'; // fallback

    const [, h, s, l] = hslMatch.map(Number);
    const [r, g, b] = this.hslToRgb(h, s / 100, l / 100);

    const bgLuminance = this.relativeLuminance(r, g, b);

    const whiteContrast = this.contrastRatio(bgLuminance, 1);
    const blackContrast = this.contrastRatio(bgLuminance, 0);

    return whiteContrast >= blackContrast ? 'white' : 'black';
  }

  protected hslToRgb(h:number, s:number, l:number):[number, number, number] {
    const c = (1 - Math.abs(2 * l - 1)) * s;
    const x = c * (1 - Math.abs((h / 60) % 2 - 1));
    const m = l - c / 2;
    let r = 0, g = 0, b = 0;

    if (h < 60) [r, g, b] = [c, x, 0];
    else if (h < 120) [r, g, b] = [x, c, 0];
    else if (h < 180) [r, g, b] = [0, c, x];
    else if (h < 240) [r, g, b] = [0, x, c];
    else if (h < 300) [r, g, b] = [x, 0, c];
    else [r, g, b] = [c, 0, x];

    return [
      Math.round((r + m) * 255),
      Math.round((g + m) * 255),
      Math.round((b + m) * 255),
    ];
  }

  protected relativeLuminance(r:number, g:number, b:number):number {
    const srgb = [r, g, b].map(c => {
      const s = c / 255;
      return s <= 0.03928
        ? s / 12.92
        : Math.pow((s + 0.055) / 1.055, 2.4);
    });

    return 0.2126 * srgb[0] + 0.7152 * srgb[1] + 0.0722 * srgb[2];
  }

  protected contrastRatio(l1:number, l2:number):number {
    const [bright, dark] = l1 > l2 ? [l1, l2] : [l2, l1];
    return (bright + 0.05) / (dark + 0.05);
  }
}
