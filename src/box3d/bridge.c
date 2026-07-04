#include "box3d/box3d.h"
#include <stdint.h>

uint32_t bw_create_world(float gx, float gy, float gz)
{
    b3WorldDef def = b3DefaultWorldDef();
    def.gravity = (b3Vec3){gx, gy, gz};
    return b3StoreWorldId(b3CreateWorld(&def));
}

void bw_destroy_world(uint32_t world)
{
    b3DestroyWorld(b3LoadWorldId(world));
}

void bw_step(uint32_t world, float time_step, int sub_step_count)
{
    b3World_Step(b3LoadWorldId(world), time_step, sub_step_count);
}

uint64_t bw_create_body(uint32_t world, float x, float y, float z, int type)
{
    b3BodyDef def = b3DefaultBodyDef();
    def.position = (b3Vec3){x, y, z};
    def.type = (b3BodyType)type;
    return b3StoreBodyId(b3CreateBody(b3LoadWorldId(world), &def));
}

void bw_destroy_body(uint64_t body)
{
    b3DestroyBody(b3LoadBodyId(body));
}

void bw_get_body_position(uint64_t body, float* x, float* y, float* z)
{
    b3Vec3 pos = b3Body_GetPosition(b3LoadBodyId(body));
    *x = pos.x;
    *y = pos.y;
    *z = pos.z;
}

uint64_t bw_create_box_shape(uint64_t body, float hx, float hy, float hz)
{
    b3BoxHull box = b3MakeBoxHull(hx, hy, hz);
    b3ShapeDef def = b3DefaultShapeDef();
    def.density = 1.0f;
    return b3StoreShapeId(b3CreateHullShape(b3LoadBodyId(body), &def, &box.base));
}
