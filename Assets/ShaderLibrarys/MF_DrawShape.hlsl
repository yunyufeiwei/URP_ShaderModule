#ifndef MF_DRAWSHAPE_INCLUDED
#define MF_DRAWSHAPE_INCLUDED

float Point(float2 position , float size , float2 uv)
{
	float2 v = 1 - step(size / 2.0 , abs(uv - position.xy));
	return v.x * v.y;
}

//绘制线
float Line(float2 point1, float2 point2, float width, float aa, float2 uv)
{
	if(point1.x == point2.x) //避免下面的除0问题
	{
		return 1 - smoothstep(width/2.0, width/2.0 + aa, abs(uv.x - point1.x));
	}

	float k = (point1.y - point2.y) / (point1.x - point2.x);
	float b = point1.y - k * point1.x;

	float d = abs(k * uv.x - uv.y + b) / sqrt(k * k + 1);
	float t = smoothstep(width/2.0, width/2.0 + aa, d);
	return 1.0 - t;
}

//绘制线段
float LineSegment(float2 point1, float2 point2, float width, float smooth, float2 uv)
{
	float smallerX = min(point1.x, point2.x);
	float biggerX = max(point1.x, point2.x);
	float smallerY = min(point1.y, point2.y);
	float biggerY = max(point1.y, point2.y);

	if(point1.x == point2.x) //避免下面的除0问题
	{
		if(uv.y < smallerY || uv.y > biggerY) 
			return 0;

		return 1 - smoothstep(width/2.0, width/2.0+smooth, abs(uv.x - point1.x));
	}
	else if(point1.y == point2.y)
	{
		if(uv.x < smallerX || uv.x > biggerX)
			return 0;
	}
	else 
	{
		if(uv.x < smallerX || uv.x > biggerX || uv.y < smallerY || uv.y > biggerY)
			return 0;
	}

	float k = (point1.y - point2.y) / (point1.x - point2.x);
	float b = point1.y - k * point1.x;

	float d = abs(k * uv.x - uv.y + b) / sqrt(k * k + 1);
	float t = smoothstep(width/2.0, width/2.0 + smooth, d);
	return 1.0 - t;
}

//border : (left, right, bottom, top), all should be [0, 1]
float Rect(float4 border, float2 uv)
{
	float v1 = step(border.x, uv.x);
	float v2 = step(border.y, 1 - uv.x);
	float v3 = step(border.z, uv.y);
	float v4 = step(border.w, 1 - uv.y);
	return v1 * v2 * v3 * v4;
}

float Circle(float2 center, float radius, float2 uv)
{
	return 1 - step(radius, distance(uv, center));
}

float SmoothCircle(float2 center, float radius, float smoothWidth, float2 uv)
{
	return 1 - smoothstep(radius - smoothWidth, radius, distance(uv, center));
}

//y = kx 方程
float Equation(float2 uv, float kx)
{
	return smoothstep(kx - 0.01, kx, uv.y) - smoothstep(kx, kx + 0.01, uv.y);
}

#endif