use std::fmt::format;

use worker::*;

#[event(fetch)]
async fn main(req: Request, env: Env, ctx: Context) -> Result<Response> {
    let router = Router::new();

    router
        .get_async(
            "/v1/file/:id",
            |_req, _ctx| async move {
                if let Some(id) = _ctx.param("id") {
                    Response::from_html(format!("Requested id is: {}.", id))
                } else {
                    Response::error("No ID provided.", 400)
                }
            }
        )
        .run(req, env).await
}
