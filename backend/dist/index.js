"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const dotenv_1 = __importDefault(require("dotenv"));
const http_1 = __importDefault(require("http"));
const webhooks_1 = __importDefault(require("./api/webhooks"));
const sync_1 = __importDefault(require("./api/sync"));
const courses_1 = __importDefault(require("./api/courses"));
const pacing_1 = __importDefault(require("./api/pacing"));
const simulations_1 = __importDefault(require("./api/simulations"));
const analytics_1 = __importDefault(require("./api/analytics"));
const liveCoaching_1 = require("./api/liveCoaching");
dotenv_1.default.config();
const app = (0, express_1.default)();
const PORT = process.env.PORT || 3000;
app.use((0, cors_1.default)());
app.use(express_1.default.json());
// Routes
app.use('/api/v1/sync/wearable', sync_1.default);
app.use('/api/v1/webhooks', webhooks_1.default);
app.use('/api/v1/courses', courses_1.default);
app.use('/api/v1/pacing', pacing_1.default);
app.use('/api/v1/simulations', simulations_1.default);
app.use('/api/v1/analytics', analytics_1.default);
app.get('/health', (req, res) => {
    res.status(200).json({ status: 'ok' });
});
const server = http_1.default.createServer(app);
(0, liveCoaching_1.setupLiveCoachingSocket)(server);
server.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
