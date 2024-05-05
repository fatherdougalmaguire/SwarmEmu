//
//  buffer.metal
//  shader test
//
//  Created by Antonio Sanchez-Rivas on 3/5/2024.
//

#include <metal_stdlib>
using namespace metal;

[[ stitchable ]] half4 interlace(float2 position, half4 color, float width, half4 replacement, float strength) {
    // If the current color is not transparent…
    if (color.a > 0.0h) {
        // If we are an alternating horizontal line…
        if (fmod(position.y, width * 2.0) <= width) {
            // Render the original color
            return color;
        } else {
            // Otherwise blend the original color with the provided color
            // at whatever strength was requested, multiplying by this pixel's
            // alpha to avoid a hard edge.
            return half4(mix(color, replacement, strength)) * color.a;
        }
    } else {
        // Use the current (transparent) color
        return color;
    }
}

float moscillate(float f) {
    return 0.5 * (sin(f) + 1);
}

[[ stitchable ]] half4 newpcg(float2 position, half4 color, device const float *screenram, int screenramsize, device const float *pcgchar, int pcgcharsize, float xcursorpos, float ycursorpos, float ypixels, float xcolumns, float charoffset, float mytime)
{
    half4 thingy;
    int screenpos;
    int pcgpos;
    int xcursor;
    int ycursor;
    
    ycursor = int(position.y) % int(ypixels); // 16 refers to pixels high - 16 for 64x16 and 11 for 80x24
    xcursor = int(position.x) % 8;  // 8 refers to pixels wide - 8 for 64x16 and 80x25
    
    screenpos = trunc(position.y/ypixels)*int(xcolumns)+trunc(position.x/8.0); // screenram - 16 refers to pixels high - 16 for 64x16 and 11 for 80x24,8 refers to pixels wide - 8 for 64x16 and 80x25, 64 refers to columns of textp[
    pcgpos = int(charoffset)+int(screenram[screenpos])*16+int(ycursor);  // 16 refers to PCG data - 16 for 64x16 and 80x24
    
    int bitmask = (128 >> int(xcursor));
    
    //return displaypcg*16+achar[pixely][pixelx];
    
    if ((int(pcgchar[pcgpos]) & bitmask)  > 0 )
    {
        //thingy = half4(1.0,0.749,0,moscillate(mytime+2 * M_PI_F));
        thingy = half4(1.0,0.749,0,1);
    }
    else
    {
        thingy = half4(0.0,0.0,0.0,1.0);
    }
    
    return thingy;
}