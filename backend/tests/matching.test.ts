import { describe, it, expect } from 'vitest';
import { matchingService } from '../src/modules/matching/matching.service';
import { LatLng } from '../src/shared/types';

describe('Matching Engine', () => {
  it('correctly calculates Haversine distance between two coordinates', () => {
    // Nagpur zero-mile monument: [21.1458, 79.0882]
    // Point ~500m north: [21.1503, 79.0882]
    const loc1: LatLng = { latitude: 21.1458, longitude: 79.0882 };
    const loc2: LatLng = { latitude: 21.1503, longitude: 79.0882 };

    const distance = matchingService.calculateDistance(loc1, loc2);
    expect(distance).toBeGreaterThan(450);
    expect(distance).toBeLessThan(550);

    // Same location returns 0 distance
    expect(matchingService.calculateDistance(loc1, loc1)).toBe(0);
  });

  it('coarsens location coordinates to ~100m grid for pre-acceptance privacy', () => {
    const exactLoc: LatLng = { latitude: 21.14587654, longitude: 79.08821234 };
    const coarsened = matchingService.coarsenLocation(exactLoc);

    // 3 decimal places precision (~111m)
    expect(coarsened.latitude).toBe(21.146);
    expect(coarsened.longitude).toBe(79.088);

    // Ensure coarsened location is different from exact location
    expect(coarsened.latitude).not.toBe(exactLoc.latitude);
    expect(coarsened.longitude).not.toBe(exactLoc.longitude);
  });

  it('provides the three-tier expansion radii sequence [500, 1000, 3000]', () => {
    const radii = matchingService.getRadii();
    expect(radii).toEqual([500, 1000, 3000]);
    expect(radii[0]).toBe(500); // Tier 1
    expect(radii[1]).toBe(1000); // Tier 2
    expect(radii[2]).toBe(3000); // Tier 3 (max radius)
  });
});
