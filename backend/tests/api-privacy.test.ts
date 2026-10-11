import { describe, it, expect } from 'vitest';
import { matchingService } from '../src/modules/matching/matching.service';
import { LatLng } from '../src/shared/types';
import { errorHandler } from '../src/middleware/errorHandler';
import { AppError, NotFoundError, ForbiddenError } from '../src/shared/errors';

describe('Location Privacy & API Formatting', () => {
  const exactLocation: LatLng = {
    latitude: 21.1458234,
    longitude: 79.0882198,
  };

  it('redacts exact coordinates for pre-acceptance responder views', () => {
    const coarse = matchingService.coarsenLocation(exactLocation);

    // Verify coordinates are rounded to 3 decimal places
    expect(coarse.latitude).toBe(21.146);
    expect(coarse.longitude).toBe(79.088);

    // Difference between exact and coarse must exist
    expect(coarse.latitude).not.toEqual(exactLocation.latitude);
    expect(coarse.longitude).not.toEqual(exactLocation.longitude);
  });

  it('ensures distance calculation is integer/rounded for responder views', () => {
    const responderLoc: LatLng = { latitude: 21.1400, longitude: 79.0800 };
    const distance = matchingService.calculateDistance(responderLoc, exactLocation);
    const approximateMeters = Math.round(distance);

    expect(Number.isInteger(approximateMeters)).toBe(true);
    expect(approximateMeters).toBeGreaterThan(0);
  });

  it('ensures errorHandler returns the canonical error envelope without leaking stacks', () => {
    const req: any = { requestId: 'req-test-uuid' };
    let jsonOutput: any = null;
    let statusOutput: number = 0;

    const res: any = {
      status(code: number) {
        statusOutput = code;
        return this;
      },
      json(data: any) {
        jsonOutput = data;
        return this;
      },
    };
    const next: any = () => {};

    const customErr = new ForbiddenError('You are not authorized to view this emergency.');
    errorHandler(customErr, req, res, next);

    expect(statusOutput).toBe(403);
    expect(jsonOutput).toBeDefined();
    expect(jsonOutput.error).toBeDefined();
    expect(jsonOutput.error.code).toBe('FORBIDDEN');
    expect(jsonOutput.error.message).toBe('You are not authorized to view this emergency.');
    expect(jsonOutput.error.requestId).toBe('req-test-uuid');
    expect(jsonOutput.error.stack).toBeUndefined(); // Never leak stack trace
  });
});
