import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { config } from '../../config';
import { User } from '../../models/User';
import { ResponderProfile } from '../../models/ResponderProfile';
import { PRIVILEGED_ROLES, RESPONDER_ROLES, Role } from '../../shared/enums';
import { ConflictError, UnauthorizedError, ValidationError } from '../../shared/errors';
import { RegisterInput, LoginInput } from './auth.validation';

const SALT_ROUNDS = 12;

export class AuthService {
  /**
   * Register a new user. Creates a ResponderProfile automatically for responder roles.
   * Rejects self-assignment of privileged roles (VERIFIER, ADMIN).
   */
  async register(input: RegisterInput) {
    // Guard against self-assigning privileged roles
    if (PRIVILEGED_ROLES.has(input.requestedRole)) {
      throw new ValidationError(
        'Cannot self-assign a privileged role. Contact an administrator.',
      );
    }

    // Check for existing phone
    const existing = await User.findOne({ phone: input.phone });
    if (existing) {
      throw new ConflictError(
        'PHONE_ALREADY_REGISTERED',
        'A user with this phone number already exists.',
      );
    }

    const passwordHash = await bcrypt.hash(input.password, SALT_ROUNDS);

    const user = await User.create({
      displayName: input.displayName,
      phone: input.phone,
      passwordHash,
      role: input.requestedRole,
    });

    // Auto-create responder profile for responder-eligible roles
    if (RESPONDER_ROLES.has(user.role)) {
      await ResponderProfile.create({ userId: user._id });
    }

    const token = this.generateToken(user._id.toString(), user.role);

    return { user: user.toJSON(), token };
  }

  /**
   * Authenticate with phone + password and return a JWT.
   */
  async login(input: LoginInput) {
    const user = await User.findOne({ phone: input.phone }).select('+passwordHash');
    if (!user) {
      throw new UnauthorizedError('Invalid phone number or password.');
    }

    const valid = await bcrypt.compare(input.password, user.passwordHash);
    if (!valid) {
      throw new UnauthorizedError('Invalid phone number or password.');
    }

    const token = this.generateToken(user._id.toString(), user.role);

    return { user: user.toJSON(), token };
  }

  private generateToken(userId: string, role: Role): string {
    return jwt.sign({ userId, role }, config.jwt.secret, {
      expiresIn: config.jwt.expiresIn as string | number,
    } as jwt.SignOptions);
  }
}

export const authService = new AuthService();
