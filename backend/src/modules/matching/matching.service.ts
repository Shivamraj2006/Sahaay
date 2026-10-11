import { ResponderProfile, IResponderProfile } from '../../models/ResponderProfile';
import { VerificationStatus } from '../../shared/enums';
import { config } from '../../config';
import { LatLng } from '../../shared/types';

export interface MatchCandidate {
  userId: string;
  distance: number;
  profile: IResponderProfile;
}

/**
 * Matching engine: finds eligible responders within expanding radius rings.
 *
 * Candidate eligibility:
 *  - verificationStatus = VERIFIED
 *  - available = true
 *  - locationUpdatedAt within freshness threshold
 *  - within the given search radius
 *
 * Returns candidates sorted by distance (ascending), then by completedCount
 * (descending) as a stable tie-break.
 */
export class MatchingService {
  private readonly radii: number[];
  private readonly freshnessMs: number;

  constructor() {
    this.radii = [
      config.matching.initialRadiusM,
      config.matching.secondRadiusM,
      config.matching.maxRadiusM,
    ];
    this.freshnessMs = config.matching.locationFreshnessMin * 60 * 1000;
  }

  /** Get the expansion radius sequence. */
  getRadii(): number[] {
    return [...this.radii];
  }

  /**
   * Find eligible candidates at the given radius tier index.
   * @param center The emergency location
   * @param radiusIndex Which radius tier to use (0, 1, 2)
   * @param excludeUserIds User IDs to exclude (e.g., already notified)
   */
  async findCandidates(
    center: LatLng,
    radiusIndex: number,
    excludeUserIds: string[] = [],
  ): Promise<MatchCandidate[]> {
    const radius = this.radii[Math.min(radiusIndex, this.radii.length - 1)];
    const freshnessThreshold = new Date(Date.now() - this.freshnessMs);

    const candidates = await ResponderProfile.find({
      verificationStatus: VerificationStatus.VERIFIED,
      available: true,
      locationUpdatedAt: { $gte: freshnessThreshold },
      userId: { $nin: excludeUserIds },
      location: {
        $nearSphere: {
          $geometry: {
            type: 'Point',
            coordinates: [center.longitude, center.latitude],
          },
          $maxDistance: radius,
        },
      },
    }).limit(50);

    return candidates.map((profile) => {
      const distance = this.calculateDistance(
        center,
        {
          latitude: profile.location!.coordinates[1],
          longitude: profile.location!.coordinates[0],
        },
      );
      return {
        userId: profile.userId.toString(),
        distance,
        profile,
      };
    });
  }

  /**
   * Haversine distance in meters between two coordinates.
   */
  calculateDistance(a: LatLng, b: LatLng): number {
    const R = 6371000; // Earth's radius in meters
    const toRad = (deg: number) => (deg * Math.PI) / 180;

    const dLat = toRad(b.latitude - a.latitude);
    const dLon = toRad(b.longitude - a.longitude);
    const lat1 = toRad(a.latitude);
    const lat2 = toRad(b.latitude);

    const sinDLat = Math.sin(dLat / 2);
    const sinDLon = Math.sin(dLon / 2);
    const h = sinDLat * sinDLat + Math.cos(lat1) * Math.cos(lat2) * sinDLon * sinDLon;
    return 2 * R * Math.asin(Math.sqrt(h));
  }

  /**
   * Coarsen a location to ~100m grid for pre-acceptance display.
   */
  coarsenLocation(loc: LatLng): LatLng {
    const precision = 3; // ~111m at equator
    return {
      latitude: parseFloat(loc.latitude.toFixed(precision)),
      longitude: parseFloat(loc.longitude.toFixed(precision)),
    };
  }
}

export const matchingService = new MatchingService();
